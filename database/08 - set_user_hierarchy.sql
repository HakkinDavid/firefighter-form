create or replace function set_user_hierarchy (
  p_watched_id uuid,
  p_watcher_id uuid
) returns void as $$
begin
  PERFORM only_admins();

  insert into user_hierarchy (id, watched_by) values (p_watched_id, p_watcher_id) on conflict (id) do update set watched_by = p_watcher_id;
exception
  when others then
    raise;
end;
$$ LANGUAGE plpgsql security definer;