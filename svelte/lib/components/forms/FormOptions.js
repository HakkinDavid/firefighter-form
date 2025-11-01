// 
export async function fetchOptions(db, cfilter) {
    // Sí el filtro es un arreglo plano, se regresan las opciones
    if (Array.isArray(cfilter)) return cfilter;
    // Validación
    if (!cfilter || typeof cfilter !== 'object') return null;

    const { source, filter, column } = cfilter;
    let query = `SELECT ${column} FROM ${source}`;
    const params = [];

    if (filter) {
        const conditions = Object.entries(filter).map(([key, value]) => {
            params.push(value);
            return `${key} = ?`;
        });
        query += ` WHERE ${conditions.join(' AND ')}`;
    }

    try {
        const results = await db.query(query, params);
        return results.values.map(row => row[column]);
    } catch (e) {
        console.error("Error al obtener opciones:", e);
        return null;
    }
}