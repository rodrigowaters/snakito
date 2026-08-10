-- Ranking semanal para a tela do app.
--
-- Furo que isto fecha: a RLS de `profiles` deixa cada usuário ler só o
-- PRÓPRIO perfil (coleta mínima), mas o ranking precisa exibir usernames de
-- outros jogadores. Esta função SECURITY DEFINER é a exposição CONTROLADA:
-- devolve apenas username + números do leaderboard — nunca id, e-mail ou
-- qualquer outro campo. O advisor vai apontar "signed-in users can execute
-- security definer function": é intencional e este comentário é o registro.
create or replace function public.ranking_semanal(p_semana date default null)
returns table (
  posicao bigint,
  username text,
  best_score integer,
  total_kills integer,
  games integer
)
language sql
security definer
set search_path = ''
stable
as $$
  select
    rank() over (order by l.best_score desc, l.updated_at asc) as posicao,
    p.username,
    l.best_score,
    l.total_kills,
    l.games
  from public.leaderboard l
  join public.profiles p on p.id = l.user_id
  where l.week = coalesce(
    p_semana,
    (date_trunc('week', now() at time zone 'utc'))::date
  )
  order by posicao
  limit 100
$$;

-- Só usuário logado consulta (conta é obrigatória no app).
revoke execute on function public.ranking_semanal(date) from public, anon;
grant execute on function public.ranking_semanal(date) to authenticated;
