-- Aguas Misiones · esquema de Supabase (estado actual, proyecto hjghvofqstmcnzccgasd)
-- Fuente de verdad del backend: todo cambio de tablas o políticas se agrega acá Y se aplica en Supabase.
-- Convenciones: ids uuid · fechas = epoch en milisegundos (bigint) · dinero en centavos (bigint).

-- ===== Perfiles y roles =====
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null default '',
  role text not null default 'VENDEDOR' check (role in ('ADMIN','VENDEDOR')),
  active boolean not null default true,
  hidden boolean not null default false,              -- perfil de soporte: no se lista ni se edita desde el panel
  created_at bigint not null default (extract(epoch from now())*1000)::bigint
);
create function public.is_staff() returns boolean language sql stable security definer set search_path = public as $$
  select exists(select 1 from profiles where id = auth.uid() and active) $$;
create function public.is_admin() returns boolean language sql stable security definer set search_path = public as $$
  select exists(select 1 from profiles where id = auth.uid() and active and role = 'ADMIN') $$;
create function public.handle_new_user() returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles(id, name) values (new.id, coalesce(new.raw_user_meta_data->>'name', split_part(new.email,'@',1)));
  return new;
end $$;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();
revoke execute on function public.handle_new_user() from public, anon, authenticated;
-- Perfiles ocultos (soporte): el panel no los lista y la base rechaza cambios desde el panel.
create function public.guard_hidden_profile() returns trigger language plpgsql security definer set search_path = public as $$
begin
  if auth.role() = 'authenticated' then
    if tg_op = 'DELETE' then
      if old.hidden then raise exception 'Ese usuario esta protegido y no se puede eliminar desde el panel.'; end if;
    elsif old.hidden or new.hidden then
      raise exception 'Ese usuario esta protegido y no se puede modificar desde el panel.';
    end if;
  end if;
  if tg_op = 'DELETE' then return old; end if;
  return new;
end $$;
create trigger guard_hidden_profile_trg before update or delete on public.profiles for each row execute function public.guard_hidden_profile();
revoke execute on function public.is_admin() from public, anon;
revoke execute on function public.is_staff() from public, anon;
grant execute on function public.is_admin() to authenticated;
grant execute on function public.is_staff() to authenticated;

-- ===== Tablas =====
create table public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null, description text not null default '',
  price_cents bigint not null default 0 check (price_cents >= 0),
  active boolean not null default true,
  sort_order integer not null default 0
);
create table public.price_log (
  id uuid primary key default gen_random_uuid(),
  product_id uuid references products(id) on delete set null,
  product_name text not null, old_cents bigint not null, new_cents bigint not null,
  changed_by uuid default auth.uid(),
  changed_at bigint not null default (extract(epoch from now())*1000)::bigint
);
create table public.clients (
  id uuid primary key default gen_random_uuid(),
  name text not null, address text not null default '', phone text not null default '',
  description text not null default '', pending_amount bigint not null default 0,
  created_at bigint not null default (extract(epoch from now())*1000)::bigint,
  localidad text not null default '', reference text not null default '',
  active boolean not null default true, has_dispenser boolean not null default false,
  price_diff_cents bigint not null default 0,
  visit_days integer not null default 0 check (visit_days between 0 and 127),  -- máscara de bits Lun=1 ... Dom=64
  -- Dueño del cliente: cada vendedor tiene su propia copia. El admin ve todos.
  created_by uuid not null default auth.uid() references profiles(id)
);
create table public.cash_sessions (
  id uuid primary key default gen_random_uuid(),
  opened_at bigint not null, closed_at bigint,
  opened_by uuid not null default auth.uid() references profiles(id),
  closed_by text not null default '',
  total_cash_cents bigint not null default 0, total_transfer_cents bigint not null default 0,
  total_debit_cents bigint not null default 0, total_cents bigint not null default 0,
  is_closed boolean not null default false,
  counted_cash_cents bigint,                       -- arqueo del administrador (panel)
  review_status text not null default 'PENDIENTE' check (review_status in ('PENDIENTE','CONFORME','OBSERVADO')),
  review_note text not null default '', reviewed_by uuid, reviewed_at bigint,
  total_expenses_cents bigint not null default 0,  -- los tres siguientes los calcula la app al cerrar
  expected_cash_cents bigint not null default 0,
  counted_cents bigint not null default 0,
  closing_note text not null default '',            -- comentario opcional del vendedor al cerrar la caja
  left_in_cash_cents bigint not null default 0 check (left_in_cash_cents >= 0),  -- dinero que queda en la caja (cambio)
  opening_cash_cents bigint not null default 0 check (opening_cash_cents >= 0),  -- cambio inicial: lo que dejó el cierre anterior
  total_income_cents bigint not null default 0 check (total_income_cents >= 0)   -- ingresos de dinero registrados en la caja
);
create table public.sales (
  id uuid primary key default gen_random_uuid(),
  client_id uuid references clients(id) on delete set null,
  cash_session_id uuid references cash_sessions(id) on delete set null,
  total_cents bigint not null default 0,
  extra_cents bigint not null default 0,          -- aditivo manual de la venta (puede ser negativo)
  payment_type text not null default 'EFECTIVO' check (payment_type in ('EFECTIVO','TRANSFERENCIA','TARJETA','DEBITO')),
  is_on_account boolean not null default false, is_voided boolean not null default false,
  void_reason text not null default '', notes text not null default '',
  created_by uuid not null default auth.uid() references profiles(id),
  created_at bigint not null,
  paid_cents bigint not null default 0,
  payment_type2 text not null default '' check (payment_type2 in ('','EFECTIVO','TRANSFERENCIA','TARJETA','DEBITO')),  -- segundo medio si se pagó dividido
  paid2_cents bigint not null default 0 check (paid2_cents >= 0 and paid2_cents <= paid_cents)  -- parte cobrada con el segundo medio
);
create table public.sale_items (
  id uuid primary key default gen_random_uuid(),
  sale_id uuid not null references sales(id) on delete cascade,
  product_id uuid not null references products(id),
  quantity int not null default 1 check (quantity > 0),
  unit_price_cents bigint not null default 0, subtotal_cents bigint not null default 0
);
create table public.payments (                     -- cobros de fiado
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references clients(id),
  sale_id uuid,                                    -- sin FK a propósito: puede ser una venta histórica no subida
  cash_session_id uuid references cash_sessions(id) on delete set null,
  amount_cents bigint not null check (amount_cents > 0),
  method text not null default 'EFECTIVO' check (method in ('EFECTIVO','TRANSFERENCIA','TARJETA','DEBITO')),
  note text not null default '',
  created_by uuid not null default auth.uid() references profiles(id),
  created_at bigint not null
);
create table public.cash_movements (               -- ingresos y egresos de caja
  id uuid primary key default gen_random_uuid(),
  cash_session_id uuid not null references cash_sessions(id) on delete cascade,
  type text not null check (type in ('INGRESO','EGRESO')),
  concept text not null default '',
  amount_cents bigint not null check (amount_cents >= 0),
  method text not null default 'EFECTIVO' check (method in ('EFECTIVO','TRANSFERENCIA','TARJETA','DEBITO')),
  created_by uuid not null default auth.uid() references profiles(id),
  created_at bigint not null
);
create index on sales(cash_session_id);  create index on sales(created_by);
create index on sale_items(sale_id);     create index on cash_sessions(opened_by);
create index on payments(cash_session_id); create index on payments(client_id);
create index on cash_movements(cash_session_id);
create index on clients(created_by);
create index on products(sort_order);

-- ===== Triggers =====
create function public.log_price_change() returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.price_cents <> old.price_cents then
    insert into price_log(product_id, product_name, old_cents, new_cents) values (new.id, new.name, old.price_cents, new.price_cents);
  end if;
  return new;
end $$;
revoke execute on function public.log_price_change() from public, anon, authenticated;
create trigger products_price_log after update on public.products for each row execute function public.log_price_change();

create function public.guard_cash_session() returns trigger language plpgsql set search_path = public as $$
begin
  if not is_admin() then
    if old.is_closed then raise exception 'La caja ya está cerrada'; end if;
    new.counted_cash_cents := old.counted_cash_cents; new.review_status := old.review_status;
    new.review_note := old.review_note; new.reviewed_by := old.reviewed_by;
    new.reviewed_at := old.reviewed_at; new.opened_by := old.opened_by;
  end if;
  return new;
end $$;
create trigger cash_sessions_guard before update on public.cash_sessions for each row execute function public.guard_cash_session();

-- ===== Seguridad (RLS) =====
alter table profiles enable row level security;      alter table products enable row level security;
alter table price_log enable row level security;     alter table clients enable row level security;
alter table cash_sessions enable row level security; alter table sales enable row level security;
alter table sale_items enable row level security;    alter table payments enable row level security;
alter table cash_movements enable row level security;

create policy profiles_read on profiles for select to authenticated using (id = auth.uid() or is_admin());
create policy profiles_admin on profiles for all to authenticated using (is_admin()) with check (is_admin());
create policy products_read on products for select to authenticated using (is_staff());
create policy products_admin on products for all to authenticated using (is_admin()) with check (is_admin());
create policy price_log_read on price_log for select to authenticated using (is_admin());
create policy clients_read on clients for select to authenticated using (is_admin() or (is_staff() and created_by = auth.uid()));
create policy clients_insert on clients for insert to authenticated with check (is_staff() and created_by = auth.uid());
create policy clients_update on clients for update to authenticated
  using (is_admin() or (is_staff() and created_by = auth.uid()))
  with check (is_admin() or created_by = auth.uid());
create policy clients_delete on clients for delete to authenticated using (is_admin());
create policy sessions_read on cash_sessions for select to authenticated using (is_admin() or (is_staff() and opened_by = auth.uid()));
create policy sessions_insert on cash_sessions for insert to authenticated with check (is_staff() and opened_by = auth.uid());
create policy sessions_update on cash_sessions for update to authenticated
  using (is_admin() or (is_staff() and opened_by = auth.uid())) with check (is_admin() or opened_by = auth.uid());
create policy sales_read on sales for select to authenticated using (is_admin() or (is_staff() and created_by = auth.uid()));
create policy sales_insert on sales for insert to authenticated with check (is_staff() and created_by = auth.uid());
create policy sales_update on sales for update to authenticated
  using (is_admin() or (is_staff() and created_by = auth.uid()
    and exists(select 1 from cash_sessions c where c.id = cash_session_id and not c.is_closed)))
  with check (is_admin() or created_by = auth.uid());
create policy items_read on sale_items for select to authenticated using (exists(select 1 from sales s where s.id = sale_id));
create policy items_insert on sale_items for insert to authenticated
  with check (exists(select 1 from sales s where s.id = sale_id and (s.created_by = auth.uid() or is_admin())));
create policy items_admin on sale_items for update to authenticated using (is_admin()) with check (is_admin());
create policy items_admin_del on sale_items for delete to authenticated using (is_admin());
create policy payments_read on payments for select to authenticated using (is_admin() or (is_staff() and created_by = auth.uid()));
create policy payments_insert on payments for insert to authenticated with check (is_staff() and created_by = auth.uid());
create policy payments_admin on payments for all to authenticated using (is_admin()) with check (is_admin());
create policy movements_read on cash_movements for select to authenticated using (is_admin() or (is_staff() and created_by = auth.uid()));
create policy movements_insert on cash_movements for insert to authenticated
  with check (is_staff() and created_by = auth.uid() and exists(select 1 from cash_sessions c where c.id = cash_session_id));
create policy movements_admin on cash_movements for all to authenticated using (is_admin()) with check (is_admin());
