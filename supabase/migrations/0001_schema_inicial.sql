-- Snakito — schema inicial (docs §6)
-- Regras de ouro:
--   · Coleta mínima: e-mail fica SÓ em auth.users (o docs lista e-mail em
--     profiles, mas duplicá-lo violaria o próprio princípio de coleta mínima
--     do §9 — desvio documentado aqui).
--   · Escrita de score APENAS pela Edge Function `submit_session`
--     (service role); RLS bloqueia INSERT direto de clientes.
--   · Leaderboard semanal denormalizado, atualizado por trigger.

-- ============================================================ profiles
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  username text unique not null
    check (char_length(username) between 3 and 20),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "perfil: dono lê"
  on public.profiles for select to authenticated
  using (id = (select auth.uid()));

create policy "perfil: dono cria"
  on public.profiles for insert to authenticated
  with check (id = (select auth.uid()));

create policy "perfil: dono atualiza"
  on public.profiles for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- ======================================================== game_sessions
-- Estatísticas de partida + níveis de buff (§2.6.3: a validação de
-- plausibilidade precisa conhecer os buffs para calibrar os limites).
create table public.game_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  seed bigint not null,
  started_at timestamptz not null,
  duration_seconds integer not null check (duration_seconds between 1 and 300),
  final_rank integer not null check (final_rank between 1 and 100),
  score integer not null check (score >= 0),
  size_reached integer not null check (size_reached >= 1),
  kills integer not null check (kills >= 0),
  food_eaten integer not null check (food_eaten >= 0),
  challenge smallint check (challenge in (0, 1)),  -- null = Arcade
  challenge_completed boolean,
  buff_speed_level smallint not null default 0 check (buff_speed_level between 0 and 10),
  buff_magnet_level smallint not null default 0 check (buff_magnet_level between 0 and 10),
  buff_start_points_level smallint not null default 0 check (buff_start_points_level between 0 and 10),
  client_version text not null,
  created_at timestamptz not null default now()
);

create index game_sessions_user_created_idx
  on public.game_sessions (user_id, created_at desc);

alter table public.game_sessions enable row level security;

create policy "sessões: dono lê"
  on public.game_sessions for select to authenticated
  using (user_id = (select auth.uid()));
-- SEM policy de insert/update/delete: só a service role (Edge Function)
-- escreve — é a mitigação de plausibilidade do §6.

-- ========================================================== leaderboard
-- Denormalizado por semana ISO (segunda-feira). Ranking cosmético:
-- leitura para todo usuário autenticado (conta é obrigatória no app).
create table public.leaderboard (
  user_id uuid not null references public.profiles (id) on delete cascade,
  week date not null,
  best_score integer not null check (best_score >= 0),
  total_kills integer not null default 0,
  games integer not null default 0,
  updated_at timestamptz not null default now(),
  primary key (user_id, week)
);

create index leaderboard_week_score_idx
  on public.leaderboard (week, best_score desc);

alter table public.leaderboard enable row level security;

create policy "leaderboard: leitura autenticada"
  on public.leaderboard for select to authenticated
  using (true);
-- Escrita só via trigger (roda no insert da service role).

-- ========================================================= entitlements
-- ads_removed, skins etc. expires_at null = perpétuo (docs §6).
create table public.entitlements (
  user_id uuid not null references public.profiles (id) on delete cascade,
  entitlement_key text not null,
  granted_at timestamptz not null default now(),
  expires_at timestamptz,
  primary key (user_id, entitlement_key)
);

alter table public.entitlements enable row level security;

create policy "entitlements: dono lê"
  on public.entitlements for select to authenticated
  using (user_id = (select auth.uid()));
-- Escrita só pela validação de recibo (Edge Function do M2).

-- ============================================== trigger do leaderboard
-- A cada sessão inserida, faz upsert da linha (usuário, semana).
create or replace function public.atualizar_leaderboard()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.leaderboard (user_id, week, best_score, total_kills, games, updated_at)
  values (
    new.user_id,
    date_trunc('week', new.started_at at time zone 'utc')::date,
    new.score,
    new.kills,
    1,
    now()
  )
  on conflict (user_id, week) do update set
    best_score = greatest(public.leaderboard.best_score, excluded.best_score),
    total_kills = public.leaderboard.total_kills + excluded.total_kills,
    games = public.leaderboard.games + 1,
    updated_at = now();
  return new;
end;
$$;

create trigger game_sessions_leaderboard
  after insert on public.game_sessions
  for each row execute function public.atualizar_leaderboard();
