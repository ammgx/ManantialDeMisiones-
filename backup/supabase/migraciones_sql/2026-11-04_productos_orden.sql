-- Aguas Misiones · orden manual de productos
--
-- El panel mueve los productos con ↑ ↓ y guarda `sort_order`.
-- Las apps piden la lista ordenada por `sort_order` y, si hay empate, por nombre.
--
-- Aplicar una sola vez en Supabase → SQL Editor.

alter table public.products add column if not exists sort_order integer;

-- Conservar el orden actual (alfabético) al aplicar la migración.
-- Si la columna ya existía con valores nulos o repetidos, también se normaliza.
do $$
begin
  if exists (select 1 from public.products where sort_order is null)
     or exists (select 1 from public.products group by sort_order having count(*) > 1) then
    with ordered as (
      select id, row_number() over (order by lower(name), id) - 1 as rn
      from public.products
    )
    update public.products p
    set sort_order = o.rn
    from ordered o
    where p.id = o.id;
  end if;
end $$;

alter table public.products alter column sort_order set default 0;
alter table public.products alter column sort_order set not null;

create index if not exists products_sort_order_idx on public.products(sort_order);
