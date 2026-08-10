-- Consentimento parental (docs §9, LGPD): registrado quando o usuário
-- declara ter MENOS de 13 anos no cadastro e um responsável autoriza.
--
-- Minimização de dados de propósito: NÃO guardamos idade nem data de
-- nascimento — apenas o carimbo do consentimento quando ele foi necessário.
-- Usuário 13+ fica com a coluna nula e nada mais é coletado.
alter table public.profiles
  add column parental_consent_at timestamptz;

comment on column public.profiles.parental_consent_at is
  'Momento em que um responsável autorizou o uso por menor de 13 anos. '
  'Nulo = usuário declarou 13+ no cadastro (idade não é armazenada).';
