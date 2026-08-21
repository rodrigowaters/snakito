-- Snakito — razão de compras validadas (Billing, docs §5 Fase 3)
--
-- Existe por DOIS motivos, e nenhum deles é "guardar o saldo":
--  1. IDEMPOTÊNCIA: `purchase_token` é único, então o mesmo recibo não
--     concede duas vezes (o cliente pode reenviar; a fila offline pode
--     duplicar; um atacante pode replicar).
--  2. PROVENIÊNCIA: token pertence a UM usuário. Recibo válido reenviado
--     por outra conta é rejeitado, não transferido.
--
-- A economia continua LOCAL (decisão de 13/08): consumível validado aqui
-- devolve ao cliente O QUE creditar, e o saldo segue no aparelho. O que
-- vive no servidor é o direito perpétuo (`entitlements`) e esta razão.

create table public.purchases (
  purchase_token text primary key,
  user_id uuid not null references public.profiles (id) on delete cascade,
  product_id text not null,
  -- "inapp" (não consumível/entitlement) ou "consumivel" (moedas/tickets)
  tipo text not null check (tipo in ('inapp', 'consumivel')),
  -- o que foi concedido, para auditoria e para responder igual num reenvio
  concedido jsonb not null default '{}'::jsonb,
  validated_at timestamptz not null default now()
);

create index purchases_user_idx on public.purchases (user_id);

alter table public.purchases enable row level security;

-- Dono lê o próprio histórico (a tela "Restaurar compras" usa isto).
create policy "purchases: dono lê"
  on public.purchases for select to authenticated
  using (user_id = (select auth.uid()));

-- Escrita SÓ pela Edge Function `validate_purchase` (service role): é ela
-- que confere o recibo com a Google Play Developer API. Sem policy de
-- insert/update/delete, o cliente não grava nem com token válido.
