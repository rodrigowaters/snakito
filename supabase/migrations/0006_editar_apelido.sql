-- Editar apelido (tela 02b, M3): o dono pode atualizar SÓ o username da
-- própria linha. GRANT em nível de coluna + policy de UPDATE — o resto do
-- perfil (parental_consent_at etc.) continua intocável pelo cliente.
revoke update on public.profiles from authenticated;
grant update (username) on public.profiles to authenticated;

create policy "dono atualiza o proprio username"
  on public.profiles for update
  to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));
