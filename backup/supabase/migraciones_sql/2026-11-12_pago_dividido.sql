-- Aguas Misiones · pago dividido en dos medios
--
-- Una venta puede cobrarse con dos medios de pago (por ejemplo, mitad efectivo
-- y mitad transferencia):
--   payment_type   = primer medio   (cobrado: paid_cents - paid2_cents)
--   payment_type2  = segundo medio  ('' si la venta se cobró con un solo medio)
--   paid2_cents    = parte cobrada con el segundo medio
--
-- Aplicar una sola vez en Supabase → SQL Editor, ANTES de usar la app 1.10.0
-- (si no, la sincronización de ventas falla).

alter table public.sales add column if not exists payment_type2 text not null default '';
alter table public.sales add column if not exists paid2_cents bigint not null default 0;

alter table public.sales drop constraint if exists sales_payment_type2_check;
alter table public.sales add constraint sales_payment_type2_check
  check (payment_type2 in ('', 'EFECTIVO', 'TRANSFERENCIA', 'TARJETA', 'DEBITO'));

alter table public.sales drop constraint if exists sales_paid2_cents_check;
alter table public.sales add constraint sales_paid2_cents_check
  check (paid2_cents >= 0 and paid2_cents <= paid_cents);

-- Las ventas anteriores quedan con un solo medio (payment_type2 = '', paid2_cents = 0).
