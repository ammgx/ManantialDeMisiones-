-- Aguas Misiones · aditivo manual por venta
--
-- Las ventas de clientes con precio diferencial pueden llevar un monto extra
-- cargado en el momento (positivo suma, negativo resta). El total de la venta
-- ya incluye el aditivo.
--
-- Aplicar una sola vez en Supabase → SQL Editor.

alter table public.sales add column if not exists extra_cents bigint not null default 0;

-- Las ventas anteriores quedan con aditivo 0, así que sus totales no cambian.
