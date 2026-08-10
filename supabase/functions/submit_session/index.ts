// Snakito — Edge Function `submit_session` (docs §6)
//
// ÚNICO caminho de escrita de sessões/score (RLS bloqueia INSERT direto).
// Valida plausibilidade contra os LIMITES DO MOTOR (src/domain/game_engine.gd)
// antes de gravar — mitigação proporcional a um ranking cosmético, não
// anti-cheat blindado. Buffs entram no payload porque alteram os limites
// (docs §2.6.3).
//
// Respostas: 201 {session_id} · 400 payload inválido · 401 sem usuário ·
// 409 sem perfil · 422 implausível {motivo}.

import { createClient } from "jsr:@supabase/supabase-js@2";

// --- Limites espelhados do motor (manter em sincronia com game_engine.gd) ---
const DURACAO_MAX_SEG = 185; // 180 da partida + folga de arredondamento
const PONTOS_POR_COMIDA = 10;
const PONTOS_ABATE_MAX = 500;
const PONTOS_POR_SEGUNDO = 1;
const BUFF_PONTOS_MAX = 50; // Nv 10 × 5
const COMIDAS_POR_SEGUNDO_MAX = 3; // teto físico generoso
const ABATES_POR_SEGUNDO_MAX = 0.5; // 1 abate a cada 2s já seria frenético
const CRESCIMENTO_POR_ABATE_MAX = 15; // vítima máxima ~30 (teto de alfa) / 2
const NIVEL_BUFF_MAX = 10;
const IDADE_MAX_DIAS = 30; // fila offline pode segurar a sessão por dias
const RELOGIO_FUTURO_MAX_MS = 5 * 60 * 1000;

interface Payload {
  seed: number;
  started_at: string;
  duration_seconds: number;
  final_rank: number;
  score: number;
  size_reached: number;
  kills: number;
  food_eaten: number;
  challenge: number | null;
  challenge_completed: boolean | null;
  buff_speed_level: number;
  buff_magnet_level: number;
  buff_start_points_level: number;
  client_version: string;
}

function inteiroEm(valor: unknown, min: number, max: number): boolean {
  return typeof valor === "number" && Number.isInteger(valor) &&
    valor >= min && valor <= max;
}

/** Devolve o motivo da implausibilidade, ou null se o payload passa. */
function validar(p: Payload): string | null {
  if (!inteiroEm(p.duration_seconds, 1, DURACAO_MAX_SEG)) return "duracao";
  if (!inteiroEm(p.final_rank, 1, 100)) return "final_rank";
  if (!inteiroEm(p.kills, 0, Math.ceil(p.duration_seconds * ABATES_POR_SEGUNDO_MAX))) {
    return "abates_demais_para_a_duracao";
  }
  if (!inteiroEm(p.food_eaten, 0, p.duration_seconds * COMIDAS_POR_SEGUNDO_MAX)) {
    return "comidas_demais_para_a_duracao";
  }
  for (const nivel of [p.buff_speed_level, p.buff_magnet_level, p.buff_start_points_level]) {
    if (!inteiroEm(nivel, 0, NIVEL_BUFF_MAX)) return "nivel_de_buff";
  }
  if (p.challenge !== null && ![0, 1].includes(p.challenge)) return "desafio";
  // Desafio nunca aplica buffs (docs §2.6.3) — payload coerente ou mentira.
  if (
    p.challenge !== null &&
    (p.buff_speed_level > 0 || p.buff_magnet_level > 0 || p.buff_start_points_level > 0)
  ) return "buff_em_desafio";

  // Teto teórico de pontos: comida + abates no máximo + sobrevivência + buff.
  const pontosMax = p.food_eaten * PONTOS_POR_COMIDA +
    p.kills * PONTOS_ABATE_MAX +
    p.duration_seconds * PONTOS_POR_SEGUNDO +
    (p.challenge === null ? BUFF_PONTOS_MAX : 0);
  if (!inteiroEm(p.score, 0, pontosMax)) return "score_acima_do_teto";

  // Tamanho: 1 + comidas + crescimento máximo por abate.
  const tamanhoMax = 1 + p.food_eaten + p.kills * CRESCIMENTO_POR_ABATE_MAX;
  if (!inteiroEm(p.size_reached, 1, tamanhoMax)) return "tamanho_acima_do_teto";

  const inicio = Date.parse(p.started_at);
  if (Number.isNaN(inicio)) return "started_at";
  const agora = Date.now();
  if (inicio > agora + RELOGIO_FUTURO_MAX_MS) return "sessao_do_futuro";
  if (agora - inicio > IDADE_MAX_DIAS * 24 * 60 * 60 * 1000) return "sessao_velha_demais";

  if (typeof p.seed !== "number" || !Number.isInteger(p.seed)) return "seed";
  if (typeof p.client_version !== "string" || p.client_version.length > 32) {
    return "client_version";
  }
  return null;
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return Response.json({ erro: "use POST" }, { status: 405 });
  }

  // Quem é o usuário? (verify_jwt garante um JWT válido; aqui resolvemos o id)
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
    return Response.json({ erro: "json inválido" }, { status: 400 });
  }

  const motivo = validar(payload);
  if (motivo !== null) {
    return Response.json({ erro: "implausível", motivo }, { status: 422 });
  }

  // Escrita com service role — o único caminho que a RLS permite.
  const supabaseAdmin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const { data, error } = await supabaseAdmin
    .from("game_sessions")
    .insert({
      user_id: user.id,
      seed: payload.seed,
      started_at: payload.started_at,
      duration_seconds: payload.duration_seconds,
      final_rank: payload.final_rank,
      score: payload.score,
      size_reached: payload.size_reached,
      kills: payload.kills,
      food_eaten: payload.food_eaten,
      challenge: payload.challenge,
      challenge_completed: payload.challenge_completed,
      buff_speed_level: payload.buff_speed_level,
      buff_magnet_level: payload.buff_magnet_level,
      buff_start_points_level: payload.buff_start_points_level,
      client_version: payload.client_version,
    })
    .select("id")
    .single();

  if (error) {
    // FK de profiles: usuário autenticado mas sem perfil criado ainda.
    if (error.code === "23503") {
      return Response.json({ erro: "crie o perfil primeiro" }, { status: 409 });
    }
    console.error("submit_session:", error);
    return Response.json({ erro: "falha ao gravar" }, { status: 500 });
  }

  return Response.json({ session_id: data.id }, { status: 201 });
});
