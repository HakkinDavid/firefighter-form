create or replace function register_user (
  p_given_name varchar, p_surname1 varchar, p_surname2 varchar
) returns void as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then raise exception 'Debe estar autenticado.'; end if;

  insert into user_name values (uid, p_given_name, p_surname1, p_surname2);
  insert into user_role values (uid, 0, false); -- Todos empiezan como bombero base, un administrador (e.g. Villegas) debe promoverlo dentro del app.
exception
  when others then
    raise;
end;
$$ LANGUAGE plpgsql security definer;