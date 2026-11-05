-- Aguas Misiones · cambio de contraseñas desde el panel
--
-- Aplicar UNA sola vez en Supabase → SQL Editor (como postgres).
-- El panel llama a esta función con la sesión del administrador y la función
-- vuelve a comprobar el rol en el servidor: aunque alguien llame al endpoint
-- directamente, sin ser ADMIN no puede cambiar claves.
--
-- Las cuentas nuevas se gestionan fuera del panel.

create extension if not exists pgcrypto with schema extensions;

create or replace function public.admin_set_password(
  p_user_id uuid,
  p_password text
) returns void
language plpgsql
security definer
set search_path = public, auth, extensions
as $$
begin
  if not public.is_admin() then
    raise exception 'Solo un administrador puede cambiar contraseñas';
  end if;
  if length(coalesce(p_password, '')) < 8 then
    raise exception 'La contraseña debe tener al menos 8 caracteres';
  end if;
  if not exists (select 1 from auth.users where id = p_user_id) then
    raise exception 'Usuario inexistente';
  end if;

  update auth.users
     set encrypted_password = crypt(p_password, gen_salt('bf', 10)),
         email_confirmed_at = coalesce(email_confirmed_at, now()),
         updated_at = now()
   where id = p_user_id;
end $$;

revoke all on function public.admin_set_password(uuid, text) from public, anon;
grant execute on function public.admin_set_password(uuid, text) to authenticated;

-- Si la versión anterior del panel todavía existe en algún navegador, la
-- creación de usuarios deja de estar disponible en el servidor.
drop function if exists public.admin_create_user(text, text, text, text);

-- Que el panel vea los cambios sin esperar a que PostgREST se reinicie.
notify pgrst, 'reload schema';
