-- Aguas Misiones · ingresos de dinero en la caja (app 1.11.0)
--
-- Se pueden registrar ingresos de dinero en la caja por cualquier motivo (aportes,
-- devoluciones, etc.) desde el menú "Registrar ingreso de dinero". Cada ingreso es una fila de
-- cash_movements con type = 'INGRESO' (esa tabla ya lo permitía). Al cerrar la caja se guarda el
-- total de ingresos en cash_sessions.total_income_cents.
--
-- IMPORTANTE: aplicar en Supabase → SQL Editor ANTES de instalar la app 1.11.0.
-- La app sube y baja esta columna; si no existe, la sincronización de cajas falla.
-- Es idempotente: se puede correr más de una vez sin problema.

alter table public.cash_sessions add column if not exists total_income_cents bigint not null default 0;

alter table public.cash_sessions drop constraint if exists cash_sessions_total_income_nonneg;
alter table public.cash_sessions add constraint cash_sessions_total_income_nonneg check (total_income_cents >= 0);

-- Las cajas existentes quedan con 0 ingresos.
--
-- Nota para el panel web: el "total disponible" de una caja es
--   opening_cash_cents + total_cash_cents + total_transfer_cents + total_debit_cents
--   + total_income_cents - total_expenses_cents
-- y la diferencia es counted_cents menos ese total.
