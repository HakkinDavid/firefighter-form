<script context="module">
    class Definition {
        value = null
        localized = null

        constructor (value, localized) {
            this.value = value;
            this.localized = localized;
        }
    };
    
    class Dictionary {
        constructor (definitions) {
            for (const def in definitions) {
                this[def] = definitions[def].value;
                if (definitions[def].localized) {
                    this[definitions[def].value] = definitions[def].localized;
                    this['STR_' + def] = definitions[def].localized;
                }
            }
        }
    };

    const FORM_STATUSES = new Dictionary({
        NEW: new Definition(0, "Nuevo"),
        DRAFT: new Definition(1, "Borrador"),
        FINISHED: new Definition(2, "Completado")
    });

    const ACTION_STATUSES = new Dictionary({
        UNAUTHORIZED: new Definition("Se requiere la autorización de su superior para realizar esta acción."),
        REQUIRED: new Definition("Esta información es necesaria."),
        WRONG_FORMAT: new Definition("El usuario o la contraseña no son suficientemente largos."),
        MISMATCH: new Definition("Las contraseñas no coinciden."),
        BAD_CREDENTIALS: new Definition("Credenciales incorrectas o insuficientes."),
        AUTHORIZED: new Definition("Ha recibido autorización."),
        CANNOT_AUTH: new Definition("Por el momento no se puede autorizar esta acción. Esto probablemente es un error."),
        SIGN_ADMIN_UP: new Definition("Llama a tu supervisor para activar la aplicación.")
    });

    const NOTICE_TYPES = new Dictionary({
        INFORMATION: new Definition(0),
        ERROR: new Definition(1),
        WARNING: new Definition(2),
        SUCCESS: new Definition(3)
    });

    export { FORM_STATUSES, ACTION_STATUSES, NOTICE_TYPES };
</script>