// Snakito — Edge Function `delete_account` (docs §9)
//
// Exclusão de conta DENTRO do app: apaga o usuário do auth e o cascade das
// FKs elimina perfil, sessões e leaderboard. Não mantemos dados pessoais;
// agregados anônimos (se existirem no futuro) não referenciam o usuário.
//
// Respostas: 200 {ok} · 401 sem usuário · 405 método · 500 falha.

import { createClient } from "jsr:@supabase/supabase-js@2";

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return Response.json({ erro: "use POST" }, { status: 405 });
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

  const supabaseAdmin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const { error } = await supabaseAdmin.auth.admin.deleteUser(user.id);
  if (error) {
    console.error("delete_account:", error);
    return Response.json({ erro: "falha ao excluir" }, { status: 500 });
  }
  return Response.json({ ok: true }, { status: 200 });
});
