-- Revocar todos los permisos a public
revoke all on all tables in schema public from public;
revoke all on all sequences in schema public from public;
revoke all on all functions in schema public from public;

-- Permitir uso del schema a authenticated
grant usage on schema public to authenticated;

-- Otorgar solo select y execute sobre funciones a authenticated
grant execute on function register_user(p_given_name varchar, p_surname1 varchar, p_surname2 varchar) to authenticated;

grant execute on function is_role() to authenticated;
grant execute on function is_firefighter() to authenticated;
grant execute on function is_supervisor() to authenticated;
grant execute on function is_admin() to authenticated;
grant execute on function only_firefighters() to authenticated;
grant execute on function only_supervisors() to authenticated;
grant execute on function only_admins() to authenticated;