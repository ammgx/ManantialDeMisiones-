-- Aguas Misiones · cambio inicial de la caja (app 1.10.1)
--
-- Lo que se deja en la caja al cerrarla (left_in_cash_cents) pasa a la caja siguiente como
-- "cambio inicial" (opening_cash_cents): suma al efectivo y al total disponible, pero no
-- cuenta como venta.
--
-- IMPORTANTE: aplicar en Supabase → SQL Editor ANTES de instalar la app 1.10.1.
-- La app sube y baja esta columna; si no existe, la sincronización de cajas falla.
-- Es idempotente: se puede correr más de una vez sin problema.

alter table public.cash_sessions add column if not exists opening_cash_cents bigint not null default 0;

alter table public.cash_sessions drop constraint if exists cash_sessions_opening_cash_nonneg;
alter table public.cash_sessions add constraint cash_sessions_opening_cash_nonneg check (opening_cash_cents >= 0);

-- Las cajas existentes quedan con 0. La caja que esté abierta al actualizar la app recibe el
-- cambio del último cierre en el celular y lo sube en la próxima sincronización.
--
-- Nota para el panel web: el "total disponible" de una caja es
--   opening_cash_cents + total_cash_cents + total_transfer_cents + total_debit_cents
--   - total_expenses_cents
-- y la diferencia es counted_cents menos ese total.
