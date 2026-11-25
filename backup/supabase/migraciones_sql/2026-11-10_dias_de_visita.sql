-- Aguas Misiones · días de visita fijos por cliente (ruta semanal)
--
-- Máscara de bits: Lunes = 1, Martes = 2, Miércoles = 4, Jueves = 8, Viernes = 16,
-- Sábado = 32, Domingo = 64. 0 = sin días asignados. Un cliente puede tener varios días.
--
-- IMPORTANTE: aplicar en Supabase → SQL Editor ANTES de instalar la app 1.8.0.
-- La app sube y baja esta columna; si no existe, la sincronización falla.
-- Aplicar una sola vez.

alter table public.clients add column if not exists visit_days integer not null default 0;

alter table public.clients drop constraint if exists clients_visit_days_range;
alter table public.clients add constraint clients_visit_days_range check (visit_days between 0 and 127);

-- Los clientes existentes quedan sin días asignados (0).
