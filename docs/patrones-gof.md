# Patrones GoF en la aplicación de bomberos

## Propósito del documento

Este documento explica por qué, a partir de los requerimientos funcionales y no funcionales del proyecto descritos en `README.md`, aparecen de forma natural los patrones GoF **Singleton**, **Mediator**, **Command**, **Strategy**, **Observer** y **Facade**.

La aplicación no es un CRUD aislado. Resuelve digitalización de un parte prehospitalario, operación sin conectividad, sincronización diferida, exportación a PDF, control de acceso, trazabilidad administrativa, firma y dibujo digital, campos dinámicos y validaciones condicionales. Esa combinación obliga a separar responsabilidades, encapsular decisiones de ejecución y mantener la interfaz reactiva frente a cambios de estado.

## Problema que resuelve el proyecto

El proyecto busca digitalizar el formato de atención médica y registro de incidentes, operar con o sin internet, sincronizar después, generar folios únicos, producir PDF, administrar usuarios y permitir formularios con campos dinámicos y reglas condicionales. Todo eso está concentrado en `README.md`, especialmente en los RF relacionados con digitalización, firma, bloqueo de edición, almacenamiento local, exportación a PDF, interoperabilidad, control de acceso, campos dinámicos, múltiples registros y sincronización.

En la práctica, eso produce cuatro tensiones técnicas:

1. **Un mismo estado debe compartirse entre pantallas y tareas asíncronas.**
2. **Las acciones no siempre pueden ejecutarse cuando el usuario las solicita.**
3. **La interfaz debe reaccionar sin recargar manualmente cada vista.**
4. **La complejidad de red, disco, PDF, overlays y validaciones no debe filtrarse a la UI.**

Los patrones GoF que aparecen en `lib/` responden exactamente a esas tensiones.

## Resumen

| Patrón | Problema que resuelve | Archivos principales | RF/RNF que lo empujan |
|---|---|---|---|
| Singleton | Un solo punto de verdad para estado, configuración y servicios | `lib/models/settings.dart`, `lib/models/SRE/service_reliability_engineer.dart` | RF-04, RF-07, RF-08, RF-19, RNF-07, RNF-08 |
| Mediator | Coordinar subsistemas sin acoplarlos entre sí | `lib/models/SRE/service_reliability_engineer.dart` | RF-04, RF-06, RF-19, RNF-02, RNF-04, RNF-08 |
| Command | Encapsular trabajo diferido, sincronizable y dependiente de contexto | `lib/models/SRE/Task/task.dart`, `lib/models/SRE/service_reliability_engineer.dart` | RF-04, RF-19, RF-14 |
| Strategy | Cambiar la política de ejecución o de interacción según el contexto | `lib/models/SRE/Heuristic/*`, `lib/viewmodels/dynamic_field_renderer.dart` | RF-10, RF-13, RF-20, RNF-02 |
| Observer | Actualizar la UI cuando cambian datos o trazos | `lib/models/settings.dart`, `lib/viewmodels/canvas.dart`, `lib/routes/home.dart`, `lib/routes/search.dart`, `lib/routes/users_panel.dart` | RF-14, RF-15, RNF-01, RNF-02 |
| Facade | Ocultar subsistemas complejos detrás de una API simple | `lib/models/settings.dart`, `lib/viewmodels/overlay_service.dart`, `lib/models/pdf_renderer.dart` | RF-06, RF-07, RF-19, RNF-07 |

## Singleton

En GoF, Singleton garantiza una única instancia accesible globalmente. En este proyecto esa decisión aparece porque hay información que debe permanecer coherente en toda la app: usuario actual, cachés, colas de formularios, colorimetría, clave de navegación y estado de depuración.

La clase `Settings` se define con una instancia estática única y un constructor privado en `lib/models/settings.dart`. Desde ahí cuelgan varios subsistemas: `navigatorKey`, `userCache`, `formsQueue`, `formsListStream`, `userCacheStream`, rutas de disco, sincronización con Supabase, lectura de plantillas y operaciones de usuario. La aplicación entera consulta y modifica ese núcleo desde múltiples pantallas.

`ServiceReliabilityEngineer` repite la misma idea en `lib/models/SRE/service_reliability_engineer.dart`: hay una sola coordinación de tareas de fondo, una sola cola de ejecución y un solo temporizador periódico que procesa trabajos. El propio `main.dart` arranca ese servicio una vez y lo deja funcionando durante toda la sesión.

### Por qué es natural aquí

La app necesita una fuente común para:

- saber quién está autenticado;
- conocer el estado de usuarios y formularios;
- decidir si se puede editar o finalizar un parte;
- manejar rutas y overlays desde cualquier pantalla;
- sincronizar en segundo plano sin duplicar schedulers.

Si hubiera múltiples instancias de `Settings` o del SRE, la app podría divergir entre pantallas, perder consistencia en la cola de sincronización o crear condiciones de carrera en cachés y escrituras locales. Singleton evita exactamente eso.

### RF y RNF relacionados

- RF-04 y RF-19, porque el estado local y la sincronización deben persistir y reintentarse sin ambigüedad.
- RF-07 y RF-08, porque la centralización de padrones, roles y permisos necesita una autoridad única.
- RNF-07 y RNF-08, porque la mantenibilidad y la recuperación dependen de un punto central de control.

## Mediator

Este es el patrón más importante del proyecto.

En GoF, Mediator encapsula cómo interactúan varios objetos para reducir el acoplamiento entre colegas. Eso es exactamente lo que hace `ServiceReliabilityEngineer`: recibe solicitudes de alto nivel, decide qué tarea corresponde, verifica heurísticas, resuelve dependencias, usa mutex para exclusión mutua y dispara acciones sobre `Settings`, disco, red, overlays y el canal nativo.

La clase registra tareas como `SaveToDisk`, `LoadFromDisk`, `SetForms`, `SyncForms`, `UpdateTemplate`, `RefreshUsers` e `IsUpdateAvailable` en `lib/models/SRE/service_reliability_engineer.dart`. Cada una se describe como un objeto `Task` y el SRE decide cuándo ejecutarla. Ningún subsistema llama directamente al resto para coordinar el flujo global; todos pasan por el mediador.

Un ejemplo visible: al iniciar la app, el SRE encadena carga desde disco, usuario actual, sincronización de formularios, actualización de plantilla y verificación de versión. Más adelante, cuando la UI cambia el estado de depuración, `Settings` no ejecuta por sí misma toda la estrategia; encola una tarea en el SRE. Cuando se detecta una actualización, el SRE crea el overlay y lo muestra mediante `OverlayService`, pero sigue siendo el coordinador del flujo.

### Por qué es natural aquí

La problemática del proyecto no es “mostrar una pantalla”, sino coordinar una red de dependencias:

- si hay red, se pueden sincronizar formularios;
- si el disco está listo, se pueden guardar y leer plantillas;
- si el usuario cambió de rol, hay que refrescar caches;
- si existe una nueva versión, hay que avisar en la interfaz;
- si una tarea depende de otra, no debe ejecutarse antes.

Todo eso sería frágil si cada clase hablara con todas las demás. El Mediator centraliza la conversación y deja a los componentes con una responsabilidad local.

### RF y RNF relacionados

- RF-04 y RF-19, porque la operación offline y la sincronización posterior requieren arbitraje de ejecución.
- RF-06, porque la generación y recuperación de plantillas y formularios debe coordinarse con almacenamiento local.
- RNF-02 y RNF-04, porque el trabajo en segundo plano y la operación sin conexión exigen control del flujo y de los recursos.
- RNF-08, porque la recuperación ante pérdida de conectividad o estado se organiza mejor desde un centro de coordinación.

## Command

En GoF, Command encapsula una solicitud como objeto para desacoplar al emisor del receptor y permitir colas, ejecuciones diferidas y variantes de comportamiento.

En este proyecto, `Task` es el comando. Tiene tres piezas clave:

- `duty`, que representa lo que se debe hacer;
- `heuristic`, que decide si la acción es viable en el contexto actual;
- `dereliction`, que representa la salida alternativa si no se puede ejecutar.

El SRE no “sabe” cómo guardar o sincronizar internamente; solo encola comandos y los procesa cuando el sistema lo permite. Esto es visible en `lib/models/SRE/Task/task.dart` y en la lógica de cola de `lib/models/SRE/service_reliability_engineer.dart`.

### Por qué es natural aquí

La app trabaja con acciones que no siempre pueden ejecutarse en el instante en que el usuario las dispara. Por ejemplo:

- guardar un parte cuando no hay conectividad;
- sincronizar formularios solo cuando haya red;
- cargar usuarios o plantillas desde disco cuando sean necesarias;
- reagendar acciones cuando una dependencia todavía está pendiente.

Encapsular cada operación como comando permite encolarla, reordenarla, marcarla como pendiente y ejecutar un plan de trabajo robusto en segundo plano.

### RF y RNF relacionados

- RF-04 y RF-19, porque el sistema debe funcionar sin conexión y sincronizar luego.
- RF-14, porque administrar formularios implica crear, guardar, finalizar, listar y eliminar bajo distintas condiciones.
- RNF-02 y RNF-08, porque el trabajo diferido ayuda a no bloquear la interfaz y mejora la resiliencia.

## Strategy

En GoF, Strategy define una familia de algoritmos intercambiables y permite que el cliente elija uno en tiempo de ejecución sin acoplarse a su implementación concreta.

En este proyecto hay dos manifestaciones claras.

La primera está en el SRE. `Heuristic` define el contrato en `lib/models/SRE/Heuristic/heuristic.dart`, y `ConnectionHeuristic` / `DiskHeuristic` implementan políticas distintas para responder si una tarea puede ejecutarse. La decisión de “cuándo sí” no está codificada dentro del scheduler; se inyecta como estrategia.

La segunda aparece en la renderización dinámica de formularios. `DynamicFieldRenderer` en `lib/viewmodels/dynamic_field_renderer.dart` selecciona en tiempo de ejecución qué widget usar según el esquema: `DateInputField`, `TimeInputField`, `MultipleInputField`, `NumberInputField`, `OptionsInputField`, `SelectField`, `TextAreaField`, `CheckboxMultipleField`, `RadioMultipleField`, `DrawingBoardField`, `TupleField` o `TextDisplayField`. Cada uno representa una estrategia de interacción distinta con el usuario.

### Por qué es natural aquí

El problema del proyecto no permite una sola política fija:

- una tarea puede depender de la red o del disco;
- un campo puede ser texto, fecha, hora, selección, lista múltiple, firma o bloque de texto;
- el mismo formulario puede variar según la definición de plantilla;
- el mismo dato debe mostrarse de manera distinta según estado y tipo.

Strategy evita una cascada de `if` rígidos repartidos por toda la app y hace que el comportamiento dependa del contexto o del esquema, no de una única implementación estática.

### RF y RNF relacionados

- RF-10, RF-13 y RF-20, porque los campos dinámicos, las validaciones y los formatos diferenciados exigen comportamientos intercambiables.
- RF-04 y RF-19, porque la heurística de ejecución depende de conectividad y disponibilidad local.
- RNF-02, porque seleccionar la estrategia correcta reduce lógica innecesaria y simplifica el flujo de ejecución.

## Observer

En GoF, Observer establece una dependencia uno-a-muchos: cuando el sujeto cambia, todos los observadores son notificados automáticamente.

La app usa este patrón de dos formas complementarias.

Primero, `Settings` publica `formsListStream` y `userCacheStream` mediante `StreamController.broadcast` en `lib/models/settings.dart`. Las pantallas `Home`, `Search` y `UsersPanel` consumen esos streams con `StreamBuilder`, de modo que la UI se refresca sola cuando cambian listas de formularios o caches de usuarios.

Segundo, `ServiceCanvasController` en `lib/viewmodels/canvas.dart` extiende `ChangeNotifier`. El widget `ServiceCanvas` se suscribe al controller y repinta cuando el controller notifica cambios. Eso permite dibujar, borrar, combinar trazos y exportarlos sin manejar manualmente cada invalidación de pantalla.

### Por qué es natural aquí

La interfaz de esta aplicación es reactiva por necesidad:

- la lista de formularios cambia cuando se sincroniza o cuando se guarda un nuevo parte;
- la lista de usuarios cambia cuando se refresca el padrón;
- el lienzo de firma cambia con cada trazo;
- el estado visible de un formulario depende de restricciones y validaciones que pueden variar en cada rebuild.

Observer evita que la UI tenga que “preguntar” constantemente por cambios; simplemente escucha.

### RF y RNF relacionados

- RF-14 y RF-15, porque la administración y consulta de formularios exige listas que se actualicen en vivo.
- RF-11 y RF-12, porque la interacción con firma/dibujo y registros múltiples debe reflejarse al instante.
- RNF-01 y RNF-02, porque una interfaz clara y fluida depende de actualización reactiva, no de refrescos manuales.

## Facade

En GoF, Facade ofrece una interfaz unificada y simplificada frente a un conjunto de subsistemas más complejos.

`Settings` es una fachada amplia sobre varias preocupaciones: Supabase, rutas de archivos, caches, sesión, formularios y sincronización. En vez de obligar a la UI a hablar con el cliente remoto, el sistema de archivos y las colas de persistencia por separado, la pantalla invoca métodos como `fetchUser`, `setForms`, `enqueueForm`, `uploadForm`, `getTemplate` o `refreshUsers`.

`OverlayService` es una fachada mucho más concreta: oculta la creación, inserción y eliminación de `OverlayEntry` y solo expone `showOverlay` y `closeCurrentOverlay`. La UI consume una API mínima para mostrar menús flotantes y alertas contextuales.

`ServicePDF.generate` también funciona como fachada de exportación. El resto de la app le entrega plantilla y datos; la clase se encarga de cargar recursos, componer el encabezado, ordenar columnas, manejar listas, renderizar tuplas, insertar dibujos y finalmente escribir el archivo PDF.

### Por qué es natural aquí

El proyecto mezcla muchas dependencias técnicas que no deberían filtrarse a todas las pantallas:

- acceso remoto a datos;
- almacenamiento local;
- composición de documentos PDF;
- overlays y modales;
- rutas y ventanas flotantes;
- ensamblado de contenido a partir de plantillas.

Facade reduce el costo cognitivo y facilita mantenimiento: la pantalla llama a una API corta y el detalle queda encapsulado.

### RF y RNF relacionados

- RF-06, porque la exportación PDF debe ser directa para el usuario, no una secuencia de llamadas dispersas.
- RF-07 y RF-19, porque la interoperabilidad y la sincronización centralizada dependen de una capa de acceso homogénea.
- RNF-07, porque la mantenibilidad mejora cuando el acceso a subsistemas está concentrado.

## Cierre

La relación entre los RF/RNF del README y estos patrones no es decorativa; es estructural.

La app necesita un único centro de estado y de servicios (`Singleton`), un coordinador de subsistemas y dependencias (`Mediator`), trabajo encapsulado y encolable (`Command`), políticas intercambiables de ejecución e interacción (`Strategy`), actualización automática de vistas (`Observer`) y una puerta de acceso simple a subsistemas complejos (`Facade`).

Esa combinación explica por qué la arquitectura del proyecto crece de forma natural hacia estos patrones: no porque se hayan agregado como ornamento teórico, sino porque responden a las restricciones reales del problema que el sistema tiene que resolver.
