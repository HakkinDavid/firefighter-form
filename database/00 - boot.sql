drop table if exists dict_roles;

-- Diccionario para tipos de usuario (roles)
CREATE TABLE dict_roles (
    id           smallserial PRIMARY KEY,
    valor        text        UNIQUE NOT NULL
);

INSERT INTO diccionario_tipo_usuario (id, valor) VALUES (0, 'bombero'), (1, 'supervisor'), (2, 'administrador');