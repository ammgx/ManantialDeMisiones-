-- Aguas Misiones · crear usuarios y cambiar contraseñas desde el panel
--
-- Aplicar UNA sola vez en Supabase → SQL Editor (como postgres).
-- El panel llama a estas funciones con la sesión del administrador y las
-- funciones vuelven a comprobar el rol en el servidor: aunque alguien llame
-- al endpoint directamente, sin ser ADMIN no puede crear ni cambiar claves.

create extension if not exists pgcrypto with schema extensions;

create or replace function public.admin_create_user(
  p_email text,
  p_password text,
  p_name text,
  p_role text default 'VENDEDOR'
) returns public.profiles
language plpgsql
security definer
set search_path = public, auth, extensions
as $$
declare
  v_email text := lower(btrim(p_email));
  v_name text := btrim(coalesce(p_name, ''));
  v_id uuid := gen_random_uuid();
  v_profile public.profiles;
begin
  if not public.is_admin() then
    raise exception 'Solo un administrador puede crear usuarios';
  end if;
  if v_email = '' or position('@' in v_email) = 0 then
    raise exception 'Email inválido';
  end if;
  if length(coalesce(p_password, '')) < 8 then
    raise exception 'La contraseña debe tener al menos 8 caracteres';
  end if;
  if p_role not in ('ADMIN', 'VENDEDOR') then
    raise exception 'Rol inválido';
  end if;
  if exists (select 1 from auth.users where lower(email) = v_email) then
    raise exception 'Ya existe un usuario con ese email';
  end if;
  if v_name = '' then
    v_name := split_part(v_email, '@', 1);
  end if;

  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data
  ) values (
    '00000000-0000-0000-0000-000000000000', v_id, 'authenticated', 'authenticated',
    v_email, crypt(p_password, gen_salt('bf')),
    now(), now(), now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object('name', v_name)
  );

  insert into auth.identities (
    user_id, identity_data, provider, provider_id,
    last_sign_in_at, created_at, updated_at
  ) values (
    v_id,
    jsonb_build_object(
      'sub', v_id::text,
      'email', v_email,
      'email_verified', true,
      'phone_verified', false
    ),
    'email', v_email, now(), now(), now()
  );

  insert into public.profiles (id, name, role, active)
  values (v_id, v_name, p_role, true)
  on conflict (id) do update
     set name = excluded.name, role = excluded.role, active = true
  returning * into v_profile;

  return v_profile;
end $$;

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
     set encrypted_password = crypt(p_password, gen_salt('bf')),
         email_confirmed_at = coalesce(email_confirmed_at, now()),
         updated_at = now()
   where id = p_user_id;
end $$;

revoke all on function public.admin_create_user(text, text, text, text) from public, anon;
revoke all on function public.admin_set_password(uuid, text) from public, anon;
grant execute on function public.admin_create_user(text, text, text, text) to authenticated;
grant execute on function public.admin_set_password(uuid, text) to authenticated;

-- Que el panel vea las funciones nuevas sin esperar a que PostgREST se reinicie.
notify pgrst, 'reload schema';
