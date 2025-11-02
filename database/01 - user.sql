-- Datos básicos
create table user_name (
  id uuid primary key references auth.users(id) on delete cascade,
  given varchar(85) not null,
  surname1 varchar(85) not null,
  surname2 varchar(85)
);

create table user_role (
  id uuid primary key references auth.users(id) on delete cascade,
  value smallint NOT NULL REFERENCES dict_roles(id) ON DELETE RESTRICT
);

create table user_hierarchy (
  id uuid primary key references auth.users(id) on delete cascade,
  watched_by uuid references auth.users(id) on delete cascade
);