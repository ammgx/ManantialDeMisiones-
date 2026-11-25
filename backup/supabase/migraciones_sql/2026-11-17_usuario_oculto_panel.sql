-- Aguas Misiones · usuario de soporte oculto (panel web)
--
-- El panel muestra y permite editar los perfiles de `profiles`. Esta migración agrega la
-- marca `hidden`: los perfiles ocultos no se listan ni se pueden modificar ni borrar desde
-- el panel (la protección se aplica también en la base, no solo en la pantalla).
--
-- Es idempotente: se puede correr más de una vez sin problema.
-- La creación de la cuenta de soporte se hace aparte, desde el panel de Supabase o la API
-- de administración de Auth. No se guardan credenciales en este archivo.

alter table public.profiles add column if not exists hidden boolean not null default false;

create or replace function public.guard_hidden_profile()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Solo los perfiles ocultos quedan protegidos; el resto se administra normal desde el panel.
  if auth.role() = 'authenticated' then
    if tg_op = 'DELETE' then
      if old.hidden then
        raise exception 'Ese usuario esta protegido y no se puede eliminar desde el panel.';
      end if;
    elsif old.hidden or new.hidden then
      raise exception 'Ese usuario esta protegido y no se puede modificar desde el panel.';
    end if;
  end if;
  if tg_op = 'DELETE' then return old; end if;
  return new;
end
$$;

drop trigger if exists guard_hidden_profile_trg on public.profiles;
create trigger guard_hidden_profile_trg
before update or delete on public.profiles
for each row execute function public.guard_hidden_profile();

-- Para crear la cuenta de soporte (ejemplo, cambiar el email y la contraseña):
--   1. Supabase → Authentication → Users → Add user (marcar "Auto Confirm User").
--   2. En SQL Editor:
--        update public.profiles
--           set name = 'Soporte', role = 'ADMIN', active = true, hidden = true
--         where id = '<uuid del usuario>';
--   3. Verificar que no aparezca en la pestaña "Usuarios" del panel.
