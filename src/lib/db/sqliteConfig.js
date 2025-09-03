import { CapacitorSQLite, SQLiteConnection, SQLiteDBConnection } from '@capacitor-community/sqlite';

const almacenamiento_formularios = 'firefighter_forms_db';

let db;

// Crear la conexión
export async function connect_db(CURRENT_PLATFORM) {
    // En el navegador web carecemos de almacenamiento persistente, entonces simplemente nos hacemos a la idea de que funciona...
    if (CURRENT_PLATFORM === 'web') {
        db = {
            execute: async function (s) {
                console.log("Ignorando instrucción DDL en el navegador...\n" + s);
            },
            run: async function (s, d) {
                console.log("Ignorando instrucción DML en el navegador...\n\t" + s + (d ? "\nCon los datos...\n\t" + d.join(", ") : ""));
            },
            query: async function (s, d) {
                console.log("Ignorando búsqueda DML en el navegador...\n\t" + s + (d ? "\nCon los datos...\n\t" + d.join(", ") : ""));
                return {values: []};
            }
        }
    }
    // En iOS y Android, esto funciona bien.
    else {
        const sqlite = new SQLiteConnection(CapacitorSQLite);
        const db_func = await sqlite.createConnection(almacenamiento_formularios, false, 'no-encryption', 1);
        await db_func.open();
        db = db_func;
    }
}

// Obtener la conexión
export function get_db() {
    return db;
}

// Inicializar la base de datos
export async function init_db() {
    await db.execute(`
        CREATE TABLE IF NOT EXISTS forms (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            filler TEXT NOT NULL,
            patient TEXT NOT NULL,
            status INTEGER NOT NULL,
            data TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS settings (
            key TEXT PRIMARY KEY NOT NULL,
            value TEXT
        );
        CREATE TABLE IF NOT EXISTS general_options (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            category TEXT NOT NULL
        );
    `);
    // Esto es temporal
    await db.execute(`DELETE FROM general_options`);
    // Esto también es temporal
    const insertQuery = `INSERT INTO general_options (id, name, category) VALUES (?, ?, ?)`;
    const values = [
        [1, 'Turno 1', 'turno'],
        [2, 'Turno 2', 'turno'],
        [3, 'Turno 3', 'turno'],
    ];
    for (const [id, name, category] of values) {
       await db.run(insertQuery, [id, name, category]);
    }
}

// Resetear la aplicación
export async function drop_db() {
    await db.execute(`
        DROP TABLE IF EXISTS forms;
        DROP TABLE IF EXISTS settings;
        DROP TABLE IF EXISTS general_options;`);
}

export async function drop_settings() {
    await db.execute(`DROP TABLE IF EXISTS settings;`)
}