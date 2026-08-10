-- Correção do advisor de segurança: a função do trigger é SECURITY DEFINER
-- e o PostgREST a expunha em /rest/v1/rpc para anon/authenticated. Função
-- de trigger não é chamável via SELECT (retorna `trigger`), então não havia
-- exploit prático — mas ninguém além do próprio trigger tem motivo para
-- executá-la.
revoke execute on function public.atualizar_leaderboard()
  from public, anon, authenticated;
