-- 01
DROP POLICY IF EXISTS user_name_select ON user_name;
create policy user_name_select on user_name
for select using (auth.uid() = id or is_under_my_watch(id) or is_watching_me(id));

DROP POLICY IF EXISTS user_role_select ON user_role;
create policy user_role_select on user_role
for select using (auth.uid() = id or is_under_my_watch(id) or is_watching_me(id));

DROP POLICY IF EXISTS user_hierarchy_select ON user_hierarchy;
create policy user_hierarchy_select on user_hierarchy
for select using (auth.uid() = id or is_under_my_watch(id));

-- 03
DROP POLICY IF EXISTS filled_in_select ON filled_in;
create policy filled_in_select on filled_in
for select using (auth.uid() = filler or is_under_my_watch(filler));