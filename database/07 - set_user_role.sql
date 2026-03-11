create or replace function set_user_role (
  p_user_id uuid,
  p_role_id smallint
) returns void as $$
begin
  PERFORM only_admins();

  update user_role set value = p_role_id where id = p_user_id;
exception
  when others then
    raise;
end;
$$ LANGUAGE plpgsql security definer;