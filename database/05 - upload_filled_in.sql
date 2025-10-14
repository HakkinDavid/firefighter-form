create or replace function upload_filled_in (
  p_id uuid,
  p_template_id uuid,
  p_status smallint,
  p_content jsonb,
  p_filled_at timestamp
) returns void as $$
begin
  INSERT INTO filled_in (id, template_id, filler, status, content, filled_at) VALUES (p_id, p_template_id, auth.uid(), p_status, p_content, p_filled_at);
exception
  when others then
    raise;
end;
$$ LANGUAGE plpgsql security definer;