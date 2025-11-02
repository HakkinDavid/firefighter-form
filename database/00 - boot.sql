-- Diccionario para tipos de usuario (roles)
CREATE TABLE dict_roles (
    id           smallserial PRIMARY KEY,
    name        text        UNIQUE NOT NULL
);

INSERT INTO dict_roles (id, name) VALUES (0, 'bombero'), (1, 'supervisor'), (2, 'administrador');