// Comparar contra una fecha puede necesitar ajuste dependiendo de como se guardan las fechas

// Pueden añadir más restricciones aquí.
function handleRestriction(fieldValue, data, restriction, value){
    switch (restriction) {
        case "notEmpty": {
            if (value && data[value]) return true;
            else return fieldValue !== "" && fieldValue !== null && fieldValue !== undefined;
        }
        case "isEmpty":
            return fieldValue === "" || fieldValue === null || fieldValue === undefined;
        case "equalTo":
            return fieldValue === value;
        case "includes":
            return Array.isArray(fieldValue) && fieldValue.includes(value);
        case "lessThan":
            return fieldValue < value;
        case "greaterThan":
            return fieldValue > value;
        case "lessThanSize":
            return fieldValue.length < value;
        case "greaterThanSize":
            return fieldValue.length > value;
        case "lessThanDate": {
            const today = new Date();
            const selectedDate = new Date(fieldValue + "T00:00:00");
            if (typeof value === "number" && Number.isInteger(value)) {
                const futureDate = new Date(today.getTime() + value * 24 * 60 * 60 * 1000);
                return selectedDate < futureDate;
            } else {
                const valueDate = new Date(data[value]);
                return selectedDate < valueDate;
            }
        }
        case "greaterThanDate": {
            const today = new Date();
            const selectedDate = new Date(fieldValue + "T00:00:00");
            if (typeof value === "number" && Number.isInteger(value)) {
                const futureDate = new Date(today.getTime() + value * 24 * 60 * 60 * 1000);
                return selectedDate > futureDate;
            } else {
                const valueDate = new Date(data[value]);
                return selectedDate > valueDate;
            }
        }
        default:
            return true;
    }
}

export function handleFieldRestrictions(data, restrictions){
    // Si no hay restricciones, no se hace nada
    if (!restrictions) {
        return null;
    }
    // Par key-array, el arreglo contiene todos los errores del campo
    const fieldErrors = {};
    for (const [key, items] of Object.entries(restrictions)) {
        items.forEach(field => {
            // Sí se trata de algún campo en una tupla
            if (field.subname && Array.isArray(data[field.name])) {
                data[field.name].forEach((tuple, idx) => {
                    const fieldValue = tuple[field.subname];
                    const passed = handleRestriction(fieldValue, data, key, field.value);

                    if (!passed) {
                        const errorMessage = field.message || `Error en ${field.subname}`;
                        if (!fieldErrors[field.name]) fieldErrors[field.name] = [];
                        if (!fieldErrors[field.name][idx]) fieldErrors[field.name][idx] = {};
                        if (!fieldErrors[field.name][idx][field.subname]) fieldErrors[field.name][idx][field.subname] = [];
                        fieldErrors[field.name][idx][field.subname].push(errorMessage);
                    }
                });
                // Sí es un campo a nivel global
            } else {
                const passed = handleRestriction(data[field.name], data, key, field.value);
                if (!passed) {
                    let errorMessage = field.message || `Error en ${field.name}`;
                    if (!fieldErrors[field.name]) fieldErrors[field.name] = [];
                    fieldErrors[field.name].push(errorMessage);
                }
            }
        });
    }
    return fieldErrors;
};

export function verifyRestrictions(data, restrictions, idx=null){
    // Por cada restricción
    for (const [key, items] of Object.entries(restrictions)) {
        // Filter es una palabra reservada, no cuenta como restricción.
        if (key === 'filter') return true;
        for (const field of items) {
            // Sí se trata de algún campo en una tupla
            if (field.subname && Array.isArray(data[field.name])) {
                const fieldValue = data[field.name][idx][field.subname];
                const passed = handleRestriction(fieldValue, data, key, field.value);
                
                if (!passed) return false
                // Sí es un campo a nivel global
            } else {
                const passed = handleRestriction(data[field.name], data, key, field.value);
                if (!passed) return false;
            }
        }
    }
    return true;
};