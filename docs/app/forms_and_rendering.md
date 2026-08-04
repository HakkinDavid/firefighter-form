# Formularios Dinámicos y Generación de PDF

El módulo de formularios permite la creación, captura, validación condicional y exportación a PDF del Formulario del Registro de Atención Prehospitalaria (FRAP).

---

## 1. Estructura de Plantillas Dinámicas

Los formularios se construyen dinámicamente a partir de plantillas almacenadas en la base de datos local (tabla `template`). Cada plantilla es una estructura JSON que contiene:

- **`formname`**: Nombre descriptivo del formulario.
- **`fields`**: Secciones del formulario que agrupan los campos de captura.
- **`order`**: Mapeo opcional para ordenar visualmente las secciones.
- **`restrictions`**: Reglas de validación aplicadas a los campos.

---

## 2. Tipos de Campos y Renderizado Dinámico

La clase [DynamicFieldRenderer](../../lib/viewmodels/dynamic_field_renderer.dart) actúa como una fábrica (**Strategy**) que selecciona el widget adecuado según el tipo de campo especificado en la plantilla:

| Tipo (`type`) | Subtipo (`inputType`) | Widget Renderizado | Uso |
|---|---|---|---|
| `input` | `text` | `TextInputField` | Captura de texto general (nombres, observaciones). |
| `input` | `number` | `NumberInputField` | Captura numérica (edad, constantes vitales). |
| `input` | `date` | `DateInputField` | Selección de fechas mediante selector nativo. |
| `input` | `time` | `TimeInputField` | Selección de horas de atención o servicio. |
| `select` | N/A | `SelectField` / `PredictiveTextSelectField` | Lista desplegable con opción de búsqueda predictiva. |
| `multiple` | `checkbox` | `CheckboxMultipleField` | Selección múltiple de opciones (síntomas, insumos). |
| `multiple` | `radio` | `RadioMultipleField` | Selección única entre opciones excluyentes. |
| `textarea` | N/A | `TextAreaField` | Campo de texto multilínea para narrativa del servicio. |
| `drawingboard` | N/A | `DrawingBoardField` | Lienzo interactivo para marcar lesiones en diagramas o capturar firmas. |
| `tuple` | N/A | `TupleField` | Tabla dinámica para agregar múltiples registros estructurados (ej. signos vitales en el tiempo). |

---

## 3. Motor de Validaciones y Visibilidad Condicional

### A. Reglas de Restricción (`handleFieldRestrictions()`)
La clase [ServiceForm](../../lib/models/form.dart) evalúa las siguientes restricciones antes de permitir finalizar un formulario:

- **`notEmpty`**: El campo no puede estar vacío o consistir únicamente de espacios.
- **`lessThan` / `greaterThan`**: Comparación de límites numéricos (ej. rangos de presión o pulso).
- **Expreosiones Regulares**:
  - `regexOnlyLetters`: Solo letras y acentos.
  - `regexOnlyIntegers`: Solo números enteros.
  - `regexOnlyNumbers`: Valores numéricos enteros o con decimales.
  - `regexPhoneNumber`: Números telefónicos válidos de 10 dígitos.
  - `regexEmail`: Correo electrónico con formato estándar.
  - `regexAlphanumeric`: Caracteres alfanuméricos y puntuación básica.

### B. Visibilidad Condicional (`shouldDisplay()`)
Un campo o sección puede mostrarse u ocultarse dinámicamente según las respuestas ingresadas en otros campos del formulario mediante la propiedad `displayOn`:
- `notEmpty`: Muestra si el campo referencia contiene un valor.
- `isEmpty`: Muestra si el campo referencia está vacío.
- `equalTo`: Muestra si el campo referencia coincide con un valor específico.
- `includes`: Muestra si la lista seleccionada en el campo referencia incluye un valor.

---

## 4. Generación de Documentos PDF

El módulo [ServicePDF](../../lib/models/pdf_renderer.dart) encapsula la exportación a formato PDF e integra los siguientes componentes:

1. **Encabezado Institucional**: Logotipos, título del servicio, folio único del incidente y timestamps.
2. **Distribución en Columnas**: Maquetación estructurada de todas las secciones del formulario.
3. **Renderizado de Tuplas y Listas**: Tablas formateadas para el historial de signos vitales e insumos.
4. **Rasterización de Dibujos y Firmas**: Convierte los trazos vectoriales del lienzo `ServiceCanvas` a imágenes PNG embebidas directamente en el documento.
5. **Impresión / Visualización**: Utiliza los paquetes `pdf` y `printing` para abrir la vista previa nativa del sistema operativo o enviar el reporte a impresoras térmicas/estándar.
