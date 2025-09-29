create or replace function upload_template (
  p_template jsonb
) returns void as $$
begin
  PERFORM only_admins();

  INSERT INTO template (content, uploader) VALUES (p_template, auth.uid());
exception
  when others then
    raise;
end;
$$ LANGUAGE plpgsql security definer;