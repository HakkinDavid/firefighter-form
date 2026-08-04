# Documentación del Sistema - Aplicación de Atención Prehospitalaria

Este directorio contiene la documentación técnica y arquitectónica del sistema de atención prehospitalaria y servicios digitales para bomberos.

## Estructura de la Documentación

- **[Arquitectura General (architecture.md)](../../docs/app/architecture.md)**: Vista de alto nivel de los módulos del sistema, flujos de navegación, patrones de diseño GoF implementados y manejo de estado reactivo.
- **[Modelo y Persistencia de Datos (database.md)](../../docs/app/database.md)**: Esquema de base de datos SQLite local, diccionario de datos, sincronización y mapeo 1:1 con la base de datos remota en Supabase.
- **[Sincronización y Motor SRE (sync_and_sre.md)](../../docs/app/sync_and_sre.md)**: Funcionamiento del *Service Reliability Engineer* (SRE), colas de trabajo, heurísticas de red/disco, control de concurrencia mediante Mutex y mecanismo de buzón de salida (*outbox*).
- **[Formularios Dinámicos y PDF (forms_and_rendering.md)](../../docs/app/forms_and_rendering.md)**: Definición de plantillas, renderizado dinámico de campos, motor de restricciones y validaciones, lienzo de firmas/dibujos y generación de reportes en PDF.

---

## Tecnologías Principales

- **Framework**: Flutter (Dart ^3.8.1)
- **Persistencia Local**: SQLite (`sqflite`)
- **Backend / Nube**: Supabase (`supabase_flutter`, PostgreSQL)
- **Generación de PDF**: `pdf`, `printing`
- **Control de Concurrencia**: `mutex`
- **Identificadores Únicos**: `uuid` (UUID v8)
