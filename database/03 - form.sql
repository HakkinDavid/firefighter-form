drop table if exists template, filled_in, dict_form_status;

create table dict_form_status (
    id smallserial primary key,
    name text UNIQUE NOT NULL
);

INSERT INTO dict_form_status VALUES (0, 'borrador'), (1, 'finalizado'), (2, 'sincronizado');

create table template (
    id serial primary key,
    content jsonb not null,
    created_at timestamp not null default now(),
    uploader uuid not null references auth.users(id)
);

create table filled_in (
    id uuid primary key,
    template_id int not null references template(id),
    filler uuid not null references auth.users(id),
    status smallint not null references dict_form_status(id),
    content jsonb not null,
    filled_at timestamp not null default now()
);