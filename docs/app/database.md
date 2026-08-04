# Modelo y Persistencia de Datos

El almacenamiento de datos en la aplicación opera bajo un modelo **offline-first** utilizando una base de datos **SQLite** local integrada a través del servicio [DatabaseService](../../lib/models/database_service.dart). El esquema local replica exactamente la estructura relacional de la base de datos PostgreSQL alojada en la nube (Supabase).

---

## 1. Esquema de la Base de Datos SQLite Local

La base de datos se almacena en el directorio de documentos de la aplicación (`bomberos.db`).

### A. Tablas del Diccionario
```sql
CREATE TABLE dict_roles (
    id INTEGER PRIMARY KEY,
    name TEXT UNIQUE NOT NULL
);
-- Valores sembrados: (0, 'bombero'), (1, 'supervisor'), (2, 'administrador')

CREATE TABLE dict_form_status (
    id INTEGER PRIMARY KEY,
    name TEXT UNIQUE NOT NULL
);
-- Valores sembrados: (0, 'borrador'), (1, 'finalizado'), (2, 'sincronizado')
```

### B. Tablas de Usuarios y Jerarquías
```sql
CREATE TABLE user_name (
    id TEXT PRIMARY KEY, -- UUID del usuario (auth.users)
    given TEXT NOT NULL,
    surname1 TEXT NOT NULL,
    surname2 TEXT
);

CREATE TABLE user_role (
    id TEXT PRIMARY KEY REFERENCES user_name(id) ON DELETE CASCADE,
    value INTEGER NOT NULL REFERENCES dict_roles(id)
);

CREATE TABLE user_hierarchy (
    id TEXT PRIMARY KEY REFERENCES user_name(id) ON DELETE CASCADE,
    watched_by TEXT REFERENCES user_name(id) ON DELETE CASCADE
);
```

### C. Tablas de Plantillas y Formularios
```sql
CREATE TABLE template (
    id INTEGER PRIMARY KEY,
    content TEXT NOT NULL, -- JSON string de la plantilla de formulario
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    uploader TEXT -- UUID del usuario creador
);

CREATE TABLE filled_in (
    id TEXT PRIMARY KEY, -- UUID v8 único por formulario
    template_id INTEGER NOT NULL REFERENCES template(id),
    filler TEXT NOT NULL, -- UUID del bombero que llenó el registro
    status INTEGER NOT NULL REFERENCES dict_form_status(id),
    content TEXT NOT NULL, -- JSON string con la respuestas del formulario
    filled_at TEXT NOT NULL -- Timestamp de llenado
);
```

### D. Tabla de Estado Local del Cliente
```sql
CREATE TABLE app_state (
    key TEXT PRIMARY KEY,
    value TEXT
);
-- Claves almacenadas: 'userId' (UUID de sesión activa), 'allowDebugging' ('true'/'false')
```

---

## 2. Protección de Precedencia de Datos Locales

Para garantizar la integridad del trabajo realizado sin conexión a internet y evitar la pérdida de información crítica en campo, el sistema aplica una regla de **Precedencia de Datos Locales**:

### Guard de Upsert Condicional
Al consultar registros remotos desde Supabase en la función `setForms()`, la inserción/actualización en SQLite ejecuta la siguiente consulta guardada:

```sql
INSERT INTO filled_in (id, template_id, filler, status, content, filled_at)
VALUES (?, ?, ?, 2, ?, ?)
ON CONFLICT(id) DO UPDATE SET
  template_id = excluded.template_id,
  filler = excluded.filler,
  status = 2,
  content = excluded.content,
  filled_at = excluded.filled_at
WHERE filled_in.status = 2;
```

### Garantías del Guard:
1. **Borradores Locales (`status = 0`)**: Si un usuario tiene un borrador local en edición, la condición `WHERE filled_in.status = 2` evalúa como falsa, **bloqueando cualquier sobrescritura desde la nube**.
2. **Buzón de Salida Pendiente (`status = 1`)**: Si un formulario está finalizado y en espera de sincronización, el registro local permanece protegido hasta que la carga en la nube responda con éxito.
3. **Reapertura por Supervisor**: Si un supervisor reabre un formulario finalizado (`editOverride`), su estado vuelve a `0`, quedando protegido de inmediato contra actualizaciones de red.

---

## 3. Modelos de Entidad en Dart

### ServiceForm ([form.dart](../../lib/models/form.dart))
Representa un registro de atención prehospitalaria:
- `id`: Identificador UUID v8.
- `templateId`: Identificador de la plantilla utilizada.
- `filler`: Identificador del usuario creador.
- `status`: Estado del registro (`0: Borrador`, `1: Finalizado / Pendiente`, `2: Sincronizado`).
- `filledAt`: Fecha y hora de llenado.
- `content`: Mapa con los valores ingresados en los campos dinámicos (textos, selecciones, imágenes en Base64, tuplas).
- `edited`: Propiedad calculada que compara la huella digital canónica JSON (`_fingerprintContent`) contra la última versión guardada.

### FirefighterUser ([user.dart](../../lib/models/user.dart))
Representa la información del personal y sus permisos:
- `id`: Identificador UUID.
- `givenName`, `firstSurname`, `secondSurname`: Nombre y apellidos.
- `role`: Nivel de privilegio (`0: Bombero`, `1: Supervisor`, `2: Administrador`).
- `watchedByUserId`: UUID del supervisor a cargo.
- `watchesUsersId`: Conjunto de UUIDs de personal bajo su supervisión.
