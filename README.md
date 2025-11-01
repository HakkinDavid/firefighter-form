# Aplicación de Atención Prehospitalaria y Servicios Digitales para Bomberos
===============================================================================

Introducción
------------
La "Aplicación de Atención Prehospitalaria y Servicios Digitales para Bomberos" es un proyecto dirigido a digitalizar, optimizar y centralizar el registro, almacenamiento y consulta de información sobre incidentes y atenciones médicas realizadas por el cuerpo de bomberos de Tijuana. La solución busca resolver problemáticas asociadas con registros manuales, falta de conectividad, necesidades legales y administrativas, así como mejorar la interoperabilidad, la usabilidad y la administración de recursos e insumos.

Objetivos
---------
1. Digitalizar el formato de atención médica y registro de incidentes, asegurando integridad, validez legal y facilidad de uso.
2. Permitir la operación en entornos con o sin conectividad a internet, habilitando la sincronización posterior.
3. Facilitar la generación, almacenamiento y consulta de formularios y reportes, incluyendo folios únicos, firmas digitales y exportación en PDF.
4. Mejorar la interoperabilidad con sistemas institucionales y la administración centralizada de padrones, inventarios y estadísticas.
5. Brindar soporte multiplataforma (principalmente iOS y Android), con interfaces intuitivas y administración flexible.

Requerimientos Funcionales
-------------------------
Todos los requerimientos funcionales se listan con un identificador (RF-XX) y una prioridad ("Sí" para prioritario, "No" para secundario). Se han integrado y priorizado conforme a la jerarquía de los documentos, resolviendo conflictos según lo indicado.

RF-01. Digitalización del Formato de Atención Médica (Prioridad: Sí)
    - Crear un formato digital con campos predefinidos basado en el formato FRAPP y formatos adicionales proporcionados.

RF-02. Inclusión de Firma Digital (Prioridad: Sí)
    - Permitir la firma digital del paciente, testigo y/o tutor.
    - Registrar nombre de tutor en caso de menores o pacientes incapaces de firmar.

RF-03. Bloqueo de Edición tras Firma (Prioridad: Sí)
    - Bloquear la edición del formulario tras la firma para garantizar la integridad de los datos. Solo un administrador podrá editar/eliminar formularios finalizados, según permisos y dispositivo local.

RF-04. Captura y Almacenamiento Local de Datos (Prioridad: Sí)
    - Implementar almacenamiento local en dispositivos móviles (iOS, Android).
    - Permitir la operación sin conexión a internet y sincronizar datos cuando se recupere la conexión.

RF-05. Generación de Folio Único (Prioridad: Sí)
    - Generar un folio único por incidente.
    - Incluir campos para fecha en que se llenó el formulario y fecha/hora del servicio.

RF-06. Exportación de Registros (Prioridad: Sí)
    - Permitir la exportación y almacenamiento de registros en PDF, generados a partir de los datos del formulario.

RF-07. Interoperabilidad y Centralización (Prioridad: Sí)
    - Alinear el uso de información con las disposiciones de la Secretaría de Salud.
    - Actualizar padrones, listas y opciones de manera centralizada.

RF-08. Control de Acceso y Usuarios (Prioridad: Sí)
    - Permitir la creación y asignación de supervisores.
    - Habilitar la operación de la aplicación a nivel de usuario.
    - Permitir recuperación de contraseña de supervisor.

RF-09. Registro de Personal y Personas (Prioridad: Sí)
    - Registrar el personal de bomberos que participó en la atención.
    - Registrar firma en caso de negativa del paciente.

RF-10. Campos Dinámicos y Validaciones (Prioridad: Sí)
    - Implementar listas desplegables para campos frecuentes (servicio médico, nivel de conciencia, tipo de servicio, etc.).
    - Permitir la opción "OTRO" con entrada manual en campos como padrón de traslado o insumos.
    - Validar campos condicionales (ej. ocultar campos si no hay traslado/intubación).
    - Permitir distinguir entre hora y fecha del servicio y del llenado.

RF-11. Registro de Lesiones en Imagen (Prioridad: Sí)
    - Permitir marcar lesiones sobre un 'cuerpo completo' en formato imagen.

RF-12. Registro de Signos Vitales Múltiples (Prioridad: Sí)
    - Permitir múltiples registros de signos vitales en distintos momentos del servicio.

RF-13. Campos Administrativos y Operativos (Prioridad: Sí)
    - Agregar campos de turno, estación y unidad con opción de autocompletar.

RF-14. Administración de Formularios (Prioridad: Sí)
    - Permitir crear, visualizar, editar (según estado), eliminar (con confirmación del supervisor) y listar formularios.
    - Formularios finalizados no pueden editarse salvo por administradores con debida justificación.
    - Permitir cambiar la administración y realizar movimientos administrativos desde la app.

RF-15. Interfaz de Usuario (Prioridad: Sí)
    - Página de bienvenida/login con imagen y botón de acceso.
    - Página de formularios activos: crear nuevo, listar, descargar PDF, eliminar, ver estado.
    - Página de formulario: visualizar/editar según permisos y estado.
    - Cerrar pestañas en el formulario como un directorio.

RF-16. Inventario y Control de Insumos (Prioridad: No)
    - Llevar control de insumos y equipos utilizados.

RF-17. Estadísticas y Reportes (Prioridad: No)
    - Generar estadísticas administrativas: cuántos datos, equipos, insumos, traslados, etc.

RF-18. Compatibilidad Multiplataforma (Prioridad: Sí)
    - Soporte para iOS y Android.

RF-19. Sincronización y Respaldo (Prioridad: Sí)
    - Sincronizar datos con la base de datos cuando se recupere la conexión a internet.

RF-20. Tratamiento Diferenciado por Tipo de Paciente (Prioridad: Sí)
    - Implementar formatos y lógica para pacientes enfermos y pacientes con trauma, conforme a formatos adicionales proporcionados.


Requerimientos No Funcionales
----------------------------
Los requerimientos no funcionales se listan con identificador (RNF-XX) y prioridad.

RNF-01. Usabilidad (Prioridad: Sí)
    - Interfaces intuitivas y amigables, con navegación clara y cierre de pestañas tipo directorio para evitar confusión.
    - Facilitar el llenado aun en turnos largos o con interrupciones.

RNF-02. Rendimiento y Eficiencia (Prioridad: Sí)
    - La aplicación debe funcionar de manera fluida en dispositivos móviles, con bajo consumo de recursos.

RNF-03. Seguridad y Privacidad (Prioridad: Sí)
    - Protección de datos personales y médicos de pacientes.
    - Control de acceso y permisos robusto.
    - Integridad de los datos (no permitir modificaciones no autorizadas).

RNF-04. Operación Offline (Prioridad: Sí)
    - La aplicación debe operar completamente offline y sincronizar datos posteriormente.

RNF-05. Interoperabilidad (Prioridad: Sí)
    - Capacidad de integrarse con sistemas institucionales y actualizar padrones centralizadamente.

RNF-06. Portabilidad (Prioridad: Sí)
    - Funcionar en diferentes sistemas operativos móviles (iOS, Android).

RNF-07. Mantenibilidad y Actualización (Prioridad: Sí)
    - Permitir la actualización de padrones, listas y opciones de manera centralizada y sencilla.
    - Facilitar la administración de la aplicación y sus datos.

RNF-08. Respaldo y Recuperación (Prioridad: Sí)
    - Asegurar respaldo de datos y mecanismos de recuperación ante pérdidas de credenciales o del dispositivo.

RNF-09. Accesibilidad (Prioridad: No)
    - Considerar buenas prácticas para accesibilidad de usuarios con discapacidad.


Próximos Pasos
--------------
1. Solicitar y recibir de bomberos el formulario final y padrones de insumos/listas a digitalizar.
2. Definir el Mínimo Producto Viable (MVP) para la primera versión de la aplicación.
3. Diseñar el prototipo del sistema, incluyendo la estructura del formulario digital y las interfaces principales.
4. Validar con bomberos que los campos del formulario y funcionalidades cumplen con los requerimientos establecidos.
5. Explorar y definir opciones de almacenamiento y sincronización considerando las restricciones de conectividad.
6. Programar una reunión de seguimiento para revisar avances, resolver dudas y ajustar el alcance según necesidades detectadas.