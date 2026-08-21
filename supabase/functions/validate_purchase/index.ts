// Snakito — Edge Function `validate_purchase` (docs §5 Fase 3)
//
// ÚNICO caminho para conceder qualquer coisa comprada. O cliente manda o
// recibo do Play; aqui ele é conferido com a Google Play Developer API
// antes de virar direito. RLS não deixa o app escrever em `entitlements`
// nem em `purchases`.
//
// Princípios:
//  · NUNCA conceder sem validar. Falta de credencial ou erro de rede
//    devolve 503 — o cliente reenfileira e tenta de novo.
//  · IDEMPOTENTE: `purchase_token` é chave primária da razão; reenvio
//    devolve exatamente o que foi concedido na primeira vez.
//  · Consumível não vira saldo aqui: a economia é LOCAL (decisão 13/08).
//    A resposta diz o que creditar e o cliente credita no aparelho.
//
// Respostas: 200 {conceder} · 400 payload · 401 sem usuário · 409 recibo
// de outra conta · 422 recibo inválido/não pago · 503 validação
// indisponível (credencial ausente ou Google fora).

import { createClient } from "jsr:@supabase/supabase-js@2";

const PACOTE = "com.rodrigowaters.snakito";

/** Catálogo — espelha `src/ui/loja/catalogo_produtos.gd` (manter em
 *  sincronia: id, tipo e o que concede). `entitlements` são perpétuos;
 *  `moedas`/`tickets` são creditados pelo cliente. */
const CATALOGO: Record<
  string,
  { tipo: "inapp" | "consumivel"; entitlements?: string[]; moedas?: number; tickets?: number }
> = {
  remover_anuncios: { tipo: "inapp", entitlements: ["ads_removed"] },
  pacote_neon: { tipo: "inapp", entitlements: ["skin_neon"] },
  pacote_cosmico: { tipo: "inapp", entitlements: ["skin_cosmico"] },
  // Combos do blueprint 09c: removem anúncio E dão saldo.
  combo_turbinado: { tipo: "inapp", entitlements: ["ads_removed"], moedas: 500 },
  combo_sem_interrupcao: { tipo: "inapp", entitlements: ["ads_removed"], tickets: 10 },
  moedas_500: { tipo: "consumivel", moedas: 500 },
  moedas_1200: { tipo: "consumivel", moedas: 1200 },
  moedas_3000: { tipo: "consumivel", moedas: 3000 },
  tickets_5: { tipo: "consumivel", tickets: 5 },
  tickets_15: { tipo: "consumivel", tickets: 15 },
  tickets_40: { tipo: "consumivel", tickets: 40 },
};

interface Payload {
  product_id: string;
  purchase_token: string;
}

/** Access token da Google via JWT assinado com a service account
 *  (`GOOGLE_SERVICE_ACCOUNT_JSON` nos secrets da função). */
async function tokenDaGoogle(): Promise<string | null> {
  const bruto = Deno.env.get("GOOGLE_SERVICE_ACCOUNT_JSON");
  if (!bruto) return null;
  let conta: { client_email: string; private_key: string };
  try {
    conta = JSON.parse(bruto);
  } catch {
    console.error("validate_purchase: GOOGLE_SERVICE_ACCOUNT_JSON não é JSON");
    return null;
  }

  const agora = Math.floor(Date.now() / 1000);
  const cabecalho = { alg: "RS256", typ: "JWT" };
  const corpo = {
    iss: conta.client_email,
    scope: "https://www.googleapis.com/auth/androidpublisher",
    aud: "https://oauth2.googleapis.com/token",
    iat: agora,
    exp: agora + 3600,
  };
  const b64 = (o: unknown) =>
    btoa(JSON.stringify(o)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
  const paraAssinar = `${b64(cabecalho)}.${b64(corpo)}`;

  // A chave vem em PEM PKCS#8 com "\n" escapado no env.
  const pem = conta.private_key.replace(/\\n/g, "\n");
  const der = Uint8Array.from(
    atob(pem.replace(/-----[^-]+-----/g, "").replace(/\s/g, "")),
    (ch) => ch.charCodeAt(0),
  );
  const chave = await crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const assinatura = new Uint8Array(
    await crypto.subtle.sign("RSASSA-PKCS1-v1_5", chave, new TextEncoder().encode(paraAssinar)),
  );
  const jwt = `${paraAssinar}.${
    btoa(String.fromCharCode(...assinatura))
      .replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "")
  }`;

  const resposta = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  if (!resposta.ok) {
    console.error("validate_purchase: OAuth da Google", resposta.status, await resposta.text());
    return null;
  }
  return (await resposta.json()).access_token ?? null;
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return Response.json({ erro: "use POST" }, { status: 400 });
  }

  const supabaseAuth = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: req.headers.get("Authorization")! } } },
  );
  const { data: { user } } = await supabaseAuth.auth.getUser();
  if (!user) {
    return Response.json({ erro: "sem usuário" }, { status: 401 });
  }

  let payload: Payload;
  try {
    payload = await req.json();
  } catch {
    return Response.json({ erro: "payload inválido" }, { status: 400 });
  }
  const produto = CATALOGO[payload.product_id];
  if (!produto || typeof payload.purchase_token !== "string" || !payload.purchase_token) {
    return Response.json({ erro: "produto ou recibo desconhecido" }, { status: 400 });
  }

  const supabaseAdmin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // Já validado antes? Devolve o MESMO resultado (reenvio, fila offline,
  // "Restaurar compras") e não concede de novo.
  const { data: jaTem } = await supabaseAdmin
    .from("purchases")
    .select("user_id, concedido")
    .eq("purchase_token", payload.purchase_token)
    .maybeSingle();
  if (jaTem) {
    if (jaTem.user_id !== user.id) {
      return Response.json({ erro: "recibo de outra conta" }, { status: 409 });
    }
    return Response.json({ conceder: jaTem.concedido, repetido: true }, { status: 200 });
  }

  const acesso = await tokenDaGoogle();
  if (!acesso) {
    // Sem credencial/Google fora: NÃO concede. O cliente tenta de novo.
    return Response.json({ erro: "validação indisponível" }, { status: 503 });
  }

  const url =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${PACOTE}` +
    `/purchases/products/${payload.product_id}/tokens/${payload.purchase_token}`;
  const conferencia = await fetch(url, { headers: { Authorization: `Bearer ${acesso}` } });
  if (conferencia.status === 404 || conferencia.status === 400) {
    return Response.json({ erro: "recibo inválido" }, { status: 422 });
  }
  if (!conferencia.ok) {
    console.error("validate_purchase: Play API", conferencia.status, await conferencia.text());
    return Response.json({ erro: "validação indisponível" }, { status: 503 });
  }
  const recibo = await conferencia.json();
  // purchaseState: 0 comprado · 1 cancelado · 2 pendente.
  if (recibo.purchaseState !== 0) {
    return Response.json({ erro: "compra não confirmada" }, { status: 422 });
  }

  const conceder = {
    entitlements: produto.entitlements ?? [],
    moedas: produto.moedas ?? 0,
    tickets: produto.tickets ?? 0,
  };

  // Razão primeiro: se dois pedidos chegarem juntos, a chave primária
  // decide quem grava e o outro cai no caminho do "repetido".
  const { error: erroRazao } = await supabaseAdmin.from("purchases").insert({
    purchase_token: payload.purchase_token,
    user_id: user.id,
    product_id: payload.product_id,
    tipo: produto.tipo,
    concedido: conceder,
  });
  if (erroRazao) {
    if (erroRazao.code === "23505") {  // corrida: alguém gravou primeiro
      return Response.json({ conceder, repetido: true }, { status: 200 });
    }
    if (erroRazao.code === "23503") {
      return Response.json({ erro: "crie o perfil primeiro" }, { status: 409 });
    }
    console.error("validate_purchase:", erroRazao);
    return Response.json({ erro: "falha ao gravar" }, { status: 500 });
  }

  // Direito perpétuo vive no servidor; saldo de consumível é do cliente.
  for (const chave of conceder.entitlements) {
    const { error } = await supabaseAdmin
      .from("entitlements")
      .upsert(
        { user_id: user.id, entitlement_key: chave },
        { onConflict: "user_id,entitlement_key" },
      );
    if (error) {
      console.error("validate_purchase: entitlement", chave, error);
      return Response.json({ erro: "falha ao conceder" }, { status: 500 });
    }
  }

  return Response.json({ conceder }, { status: 200 });
});
