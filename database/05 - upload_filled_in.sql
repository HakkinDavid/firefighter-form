create or replace function upload_filled_in (
  p_id uuid,
  p_template_id int,
  p_status smallint,
  p_content jsonb,
  p_filled_at timestamp
) returns void as $$
declare
  existing_status smallint;
  existing_filler uuid;
begin
  if p_status <> 1 then
    raise exception 'Debes marcar como finalizado el formulario para cargarlo.';
  end if;
  select status, filler into existing_status, existing_filler
  from filled_in
  where id = p_id;

  if not found then
    insert into filled_in (id, template_id, filler, status, content, filled_at)
    values (p_id, p_template_id, auth.uid(), 2, p_content, p_filled_at);
  else
    if existing_status = 0 then
      update filled_in
      set
          status = 2,
          content = p_content,
          filled_at = p_filled_at
      where id = p_id;
    elsif is_supervisor() and (existing_filler = auth.uid() or is_under_my_watch(existing_filler)) then
      update filled_in
      set
          status = 2,
          content = p_content,
          filled_at = p_filled_at
      where id = p_id;
    else
      raise exception 'No autorizado para actualizar el formulario.';
    end if;
  end if;
exception
  when others then
    raise;
end;
$$ language plpgsql security definer;