-- =====================================================================
-- Aislamiento por vendedor, celular activo y transferencia de clientes
-- Fecha: 2026-11-11 · Proyecto Supabase: hjghvofqstmcnzccgasd
--
-- Qué hace:
--   1. Agrega `clients.created_by` (dueño del cliente) y asigna todos los
--      clientes que ya existen al ADMINISTRADOR activo más antiguo.
--   2. Cambia la seguridad de `clients`: cada vendedor ve y edita solo sus
--      clientes; el administrador ve y edita todos (igual que el panel).
--   3. Crea `app_devices`: un solo celular activo por usuario. Cuando alguien
--      inicia sesión en otro celular, esa fila apunta al nuevo y el anterior
--      queda desplazado.
--   4. Crea `client_transfers`: auditoría de las transferencias de clientes
--      hechas desde el panel (incluye la deuda que se movió con la ficha).
--
-- Es seguro volver a ejecutarlo (no duplica columnas, tablas ni políticas).
-- Si no existe un ADMIN activo, el script se detiene sin cambiar datos.
-- =====================================================================

begin;

-- ---------------------------------------------------------------------
-- 1) Dueño del cliente
-- ---------------------------------------------------------------------
alter table public.clients
  add column if not exists created_by uuid references public.profiles(id);

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

alter table public.clients
  alter column created_by set default auth.uid();

alter table public.clients
  alter column created_by set not null;

create index if not exists clients_created_by_idx on public.clients(created_by);

-- ---------------------------------------------------------------------
-- 2) Seguridad de clientes: cada vendedor con los suyos; el admin con todos
-- ---------------------------------------------------------------------
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

-- ---------------------------------------------------------------------
-- 3) Celular activo por usuario
-- ---------------------------------------------------------------------
create table if not exists public.app_devices (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  device_id text not null,
  updated_at bigint not null default ((extract(epoch from now()) * 1000)::bigint)
);

alter table public.app_devices enable row level security;

drop policy if exists app_devices_read on public.app_devices;
drop policy if exists app_devices_insert on public.app_devices;
drop policy if exists app_devices_update on public.app_devices;
drop policy if exists app_devices_delete on public.app_devices;

create policy app_devices_read on public.app_devices
  for select to authenticated
  using (user_id = auth.uid() or is_admin());

create policy app_devices_insert on public.app_devices
  for insert to authenticated
  with check (user_id = auth.uid());

create policy app_devices_update on public.app_devices
  for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy app_devices_delete on public.app_devices
  for delete to authenticated
  using (user_id = auth.uid() or is_admin());

-- ---------------------------------------------------------------------
-- 4) Auditoría de transferencias de clientes
-- ---------------------------------------------------------------------
create table if not exists public.client_transfers (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.clients(id) on delete cascade,
  from_user uuid references public.profiles(id),
  to_user uuid not null references public.profiles(id),
  moved_by uuid not null default auth.uid() references public.profiles(id),
  pending_amount bigint not null default 0,
  note text not null default '',
  created_at bigint not null default ((extract(epoch from now()) * 1000)::bigint)
);

create index if not exists client_transfers_client_idx on public.client_transfers(client_id);
create index if not exists client_transfers_created_idx on public.client_transfers(created_at desc);

alter table public.client_transfers enable row level security;

drop policy if exists client_transfers_read on public.client_transfers;
drop policy if exists client_transfers_insert on public.client_transfers;

create policy client_transfers_read on public.client_transfers
  for select to authenticated
  using (is_admin());

-- La transferencia la hace el panel con una sesión de administrador.
create policy client_transfers_insert on public.client_transfers
  for insert to authenticated
  with check (is_admin() and moved_by = auth.uid());

-- ---------------------------------------------------------------------
-- 5) Permisos para la API (RLS sigue mandando)
-- ---------------------------------------------------------------------
grant select, insert, update, delete on public.app_devices to authenticated;
grant select, insert on public.client_transfers to authenticated;
grant all on public.app_devices, public.client_transfers to service_role;

-- ---------------------------------------------------------------------
-- 5) Transferencia de un cliente entre usuarios (atómica y auditada)
--    - Solo administradores.
--    - Se mueve la ficha con su deuda (`pending_amount`).
--    - Las ventas y cobros quedan a nombre del vendedor original.
--    - Se bloquea si el vendedor actual tiene una caja abierta con
--      movimientos: primero tiene que cerrarla desde la app.
-- ---------------------------------------------------------------------
create or replace function public.transfer_client(
  p_client_id uuid,
  p_to_user uuid,
  p_note text default ''
) returns public.client_transfers
language plpgsql
security definer
set search_path = public
as $$
declare
  v_from uuid;
  v_debt bigint;
  v_open boolean;
  v_row public.client_transfers;
begin
  if not is_admin() then
    raise exception 'Solo un administrador puede transferir clientes.' using errcode = '42501';
  end if;
  if p_to_user is null then
    raise exception 'Elegí el nuevo vendedor.';
  end if;
  if not exists (select 1 from public.profiles where id = p_to_user and active) then
    raise exception 'El usuario destino no está activo.';
  end if;

  select c.created_by, coalesce(c.pending_amount, 0)
    into v_from, v_debt
    from public.clients c
   where c.id = p_client_id
     for update;

  if v_from is null then
    raise exception 'El cliente no existe.';
  end if;
  if v_from = p_to_user then
    raise exception 'El cliente ya pertenece a ese usuario.';
  end if;

  -- Bloqueo: el vendedor actual no puede tener una caja abierta con movimientos.
  select exists (
    select 1
      from public.cash_sessions c
     where not c.is_closed
       and c.opened_by = v_from
       and (
         coalesce(c.total_cents, 0) <> 0
         or coalesce(c.total_cash_cents, 0) <> 0
         or coalesce(c.total_transfer_cents, 0) <> 0
         or coalesce(c.total_debit_cents, 0) <> 0
         or coalesce(c.total_expenses_cents, 0) <> 0
         or coalesce(c.expected_cash_cents, 0) <> 0
         or coalesce(c.counted_cents, 0) <> 0
         or exists (select 1 from public.sales s where s.cash_session_id = c.id)
         or exists (select 1 from public.payments p where p.cash_session_id = c.id)
         or exists (select 1 from public.cash_movements m where m.cash_session_id = c.id)
       )
  ) into v_open;
  if v_open then
    raise exception
      'El vendedor actual tiene una caja abierta con movimientos. Pedile que la cierre antes de transferir.';
  end if;

  update public.clients
     set created_by = p_to_user
   where id = p_client_id;

  insert into public.client_transfers(client_id, from_user, to_user, moved_by, pending_amount, note)
  values (p_client_id, v_from, p_to_user, auth.uid(), v_debt, coalesce(p_note, ''))
  returning * into v_row;

  return v_row;
end;
$$;

revoke all on function public.transfer_client(uuid, uuid, text) from public, anon;
grant execute on function public.transfer_client(uuid, uuid, text) to authenticated;

commit;

-- Control rápido: no debe quedar ningún cliente sin dueño.
select count(*) as clientes_sin_dueno
  from public.clients
 where created_by is null;
