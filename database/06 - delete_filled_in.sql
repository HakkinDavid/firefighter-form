create or replace function delete_filled_in (
  p_id uuid
) returns void as $$
begin
  PERFORM only_supervisors();

  DELETE FROM filled_in WHERE id = p_id AND (filler = auth.uid() OR is_under_my_watch(filler));
exception
  when others then
    raise;
end;
$$ language plpgsql security definer;