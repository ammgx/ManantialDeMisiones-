-- Aguas Misiones · datos nuevos al cerrar la caja (app 1.9.3)
--
-- La ventana "Cerrar caja" de la app permite:
--   * dejar un comentario opcional (por ejemplo, el motivo de una diferencia) -> closing_note
--   * definir cuánto dinero queda en la caja para dar cambio                  -> left_in_cash_cents
--
-- IMPORTANTE: aplicar en Supabase → SQL Editor ANTES de instalar la app 1.9.3.
-- La app sube y baja estas columnas; si no existen, la sincronización de cajas falla.
-- Es idempotente: se puede correr más de una vez sin problema.

alter table public.cash_sessions add column if not exists closing_note text not null default '';
alter table public.cash_sessions add column if not exists left_in_cash_cents bigint not null default 0;

alter table public.cash_sessions drop constraint if exists cash_sessions_left_in_cash_nonneg;
alter table public.cash_sessions add constraint cash_sessions_left_in_cash_nonneg check (left_in_cash_cents >= 0);

-- Las cajas ya cerradas quedan con comentario vacío y 0 en "queda en caja". No hace falta
-- tocar RLS ni el trigger guard_cash_session: la app manda estos datos en el mismo UPDATE que
-- cierra la caja (cuando todavía no estaba cerrada).
