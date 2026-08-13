-- Desafios 3 (Defesa) e 4 (Integração total) — docs §2.5, M3.
-- O CHECK antigo limitava challenge a 0–1 e derrubava o INSERT das sessões
-- novas com HTTP 500 (a Edge Function já aceitava 0–3 desde a v3).
alter table public.game_sessions
  drop constraint game_sessions_challenge_check;
alter table public.game_sessions
  add constraint game_sessions_challenge_check
  check (challenge = any (array[0, 1, 2, 3]));
