-- =====================================================================
-- Clientes individuales por vendedor
-- Fecha: 2026-11-03 · Proyecto Supabase: hjghvofqstmcnzccgasd
--
-- Qué hace:
--   1. Agrega la columna `created_by` (dueño del cliente).
--   2. Asigna TODOS los clientes que ya existen al ADMINISTRADOR activo
--      más antiguo (decisión del usuario).
--   3. Los clientes nuevos quedan automáticamente para quien los crea.
--   4. Cambia la seguridad (RLS): cada vendedor ve y edita solo sus
--      clientes; el administrador ve y edita todos.
--
-- Cómo aplicarlo:
--   Supabase → SQL Editor → New query → pegar todo este archivo → Run.
--   Es seguro volver a ejecutarlo (no duplica nada).
--
-- Si no existe un ADMIN activo, el script se detiene con un error claro
-- y no cambia ningún dato.
-- =====================================================================

begin;

-- 1) Dueño del cliente (primero nullable para poder completar los existentes).
alter table public.clients
  add column if not exists created_by uuid references public.profiles(id);

-- 2) Todos los clientes actuales pasan al administrador.
do $$
declare
  admin_id uuid;
begin
  select p.id
    into admin_id
    from public.profiles p
   where p.role = 'ADMIN'
     and p.active
   order by p.created_at asc, p.id asc
   limit 1;

  if admin_id is null then
    raise exception 'No hay un ADMIN activo en profiles: no se pueden asignar los clientes existentes.';
  end if;

  update public.clients
     set created_by = admin_id
   where created_by is null;
end $$;

-- 3) Desde ahora, el dueño es quien crea el cliente.
alter table public.clients
  alter column created_by set default auth.uid();

alter table public.clients
  alter column created_by set not null;

create index if not exists clients_created_by_idx on public.clients(created_by);

-- 4) Seguridad: cada vendedor con sus clientes; el admin con todos.
drop policy if exists clients_read on public.clients;
drop policy if exists clients_insert on public.clients;
drop policy if exists clients_update on public.clients;
drop policy if exists clients_delete on public.clients;

create policy clients_read on public.clients
  for select to authenticated
  using (is_admin() or (is_staff() and created_by = auth.uid()));

create policy clients_insert on public.clients
  for insert to authenticated
  with check (is_staff() and created_by = auth.uid());

create policy clients_update on public.clients
  for update to authenticated
  using (is_admin() or (is_staff() and created_by = auth.uid()))
  with check (is_admin() or created_by = auth.uid());

create policy clients_delete on public.clients
  for delete to authenticated
  using (is_admin());

commit;

-- Control rápido: no debe quedar ningún cliente sin dueño.
-- (Si esta consulta devuelve 0, la migración quedó bien.)
select count(*) as clientes_sin_dueno
  from public.clients
 where created_by is null;
