-- Para las políticas, véase 99.2 - policies.sql
-- 01
alter table user_name enable row level security;
alter table user_role enable row level security;
alter table user_hierarchy enable row level security;

-- 03
alter table dict_form_status enable row level security;
alter table dict_roles enable row level security;
alter table template enable row level security;
alter table filled_in enable row level security;