# Arquitectura General del Sistema

La **Aplicación de Atención Prehospitalaria y Servicios Digitales para Bomberos** es una solución móvil/escritorio desarrollada en **Flutter** orientada al registro, almacenamiento, consulta y sincronización de partes médicos prehospitalarios (FRAP).

---

## 1. Estructura del Código Fuente

El código en `lib/` está organizado bajo una arquitectura de capas bien delimitada:

```text
lib/
├── main.dart                          # Punto de entrada de la aplicación y configuración de rutas
├── models/                            # Modelos de dominio y servicios de persistencia/red
│   ├── database_service.dart          # Motor de base de datos SQLite local
│   ├── form.dart                      # Modelo de formulario de servicio (ServiceForm)
│   ├── logging.dart                   # Servicio de registro de eventos (Logging)
│   ├── pdf_renderer.dart              # Generador de documentos PDF (ServicePDF)
│   ├── settings.dart                  # Fachada de configuración global y streams de datos (Settings)
│   ├── user.dart                      # Modelo de usuario (FirefighterUser)
│   └── SRE/                           # Service Reliability Engineer
│       ├── service_reliability_engineer.dart # Coordinador central de tareas asíncronas
│       ├── Heuristic/                 # Heurísticas de viabilidad de tareas
│       │   ├── connection_heuristic.dart
│       │   ├── disk_heuristic.dart
│       │   └── heuristic.dart
│       └── Task/                      # Comando encapsulado de tareas
│           └── task.dart
├── routes/                            # Vistas y pantallas de la aplicación
│   ├── console.dart                   # Consola de depuración e historial de registros
│   ├── form.dart                      # Pantalla de llenado y edición de formulario dinámico
│   ├── home.dart                      # Pantalla principal con lista de formularios
│   ├── maker.dart                     # Creador/diseñador de plantillas de formularios
│   ├── preferences.dart               # Opciones de usuario y depuración
│   ├── search.dart                    # Búsqueda y filtrado de formularios
│   ├── statistics.dart                # Panel de estadísticas administrativas
│   ├── users_panel.dart               # Administración de usuarios, roles y jerarquías
│   └── welcome.dart                   # Pantalla de bienvenida e inicio de sesión
└── viewmodels/                        # Lógica de presentación y componentes reutilizables
    ├── canvas.dart                    # Controladores del lienzo de firma y dibujo
    ├── dynamic_field_renderer.dart    # Renderizador dinámico de campos de formularios
    ├── form_list.dart                 # Controladores para tarjetas y listas de formularios
    ├── header.dart                    # Componente de encabezado de navegación
    ├── overlay_service.dart           # Servicio de alertas modales y superposiciones (Overlays)
    ├── users_list.dart                # Tarjetas y vistas de lista de usuarios
    └── fields/                        # Renderizadores de tipos de entrada específicos
        ├── checkbox_multiple_field.dart
        ├── date_input_field.dart
        ├── drawing_board_field.dart
        ├── input_field.dart
        ├── multiple_input_field.dart
        ├── number_input_field.dart
        ├── options_input_field.dart
        ├── predictive_text_select_field.dart
        ├── radio_multiple_field.dart
        ├── select_field.dart
        ├── text_display_field.dart
        ├── text_input_field.dart
        ├── textarea_field.dart
        ├── time_input_field.dart
        └── tuple_field.dart
```

---

## 2. Patrones de Diseño GoF Implementados

La arquitectura resuelve requerimientos de operación offline, sincronización diferida y formularios dinámicos mediante los siguientes patrones GoF:

### Singleton
- **[Settings](../../lib/models/settings.dart)**: Centraliza el estado global de la sesión (usuario autenticado, caché de usuarios, colas de formularios y configuraciones).
- **[DatabaseService](../../lib/models/database_service.dart)**: Garantiza una única conexión manejada hacia la base de datos SQLite local.
- **[ServiceReliabilityEngineer](../../lib/models/SRE/service_reliability_engineer.dart)**: Mantiene una única instancia del planificador de tareas en segundo plano.

### Mediator
- **`ServiceReliabilityEngineer`**: Actúa como mediador central entre la interfaz de usuario, la base de datos SQLite, Supabase y los servicios de red. Ningún componente dispara operaciones complejas directamente; el SRE evalúa dependencias, aplica exclusión mutua mediante `Mutex` y ejecuta los trabajos correspondientes.

### Command
- **[Task](../../lib/models/SRE/Task/task.dart)**: Encapsula solicitudes de ejecución diferida (`duty`), la política de viabilidad (`heuristic`) y la acción alternativa (`dereliction`). Permite encolar, reintentar y resolver dependencias entre tareas asíncronas.

### Strategy
- **Heurísticas del SRE**: [ConnectionHeuristic](../../lib/models/SRE/Heuristic/connection_heuristic.dart) y [DiskHeuristic](../../lib/models/SRE/Heuristic/disk_heuristic.dart) proveen algoritmos intercambiables para validar si una tarea puede ejecutarse en el estado actual del dispositivo.
- **Renderizado Dinámico**: `DynamicFieldRenderer` selecciona en tiempo de ejecución la estrategia adecuada para visualizar y editar cada tipo de campo según el esquema de la plantilla.

### Observer
- **Streams Broadcast**: `Settings` publica `formsListStream` y `userCacheStream`. Las pantallas (`Home`, `Search`, `UsersPanel`) reaccionan automáticamente a los cambios de estado consumiendo estos streams mediante `StreamBuilder`.
- **Canvas Notifier**: `ServiceCanvasController` extiende `ChangeNotifier` para repintar eficientemente los trazos de firma e imágenes de lesiones.

### Facade
- **`Settings`**: Proporciona una interfaz unificada a la UI para autenticación, consulta de formularios, cachés y sincronización.
- **`OverlayService`**: Encapsula la creación y destrucción de `OverlayEntry` flotantes en la pila de navegación de Flutter.
- **`ServicePDF`**: Oculta la complejidad de composición del documento PDF de exportación.

---

## 3. Manejo de Estado y Reactividad

La aplicación mantiene un flujo de datos unidireccional y reactivo:

1. **Mutación de Estado**: Una acción del usuario o un evento de red modifica los datos mediante los métodos de `Settings` o del `DatabaseService`.
2. **Persistencia Local**: Los datos actualizados se escriben inmediatamente en la base de datos SQLite local.
3. **Notificación**: `Settings` emite el nuevo estado a través de sus `StreamController.broadcast`.
4. **Reconstrucción de la UI**: Los widgets suscritos (`StreamBuilder`) se reconstruyen automáticamente reflejando los datos actualizados.
