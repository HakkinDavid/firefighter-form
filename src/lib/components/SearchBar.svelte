<script>
	import Icon from "./Icon.svelte";

    let {
        queryFunc = (query, params) => {console.log(query, params)}
    } = $props();

    let sbValues = $state({
        name: "",
        sdate: "",
        edate: ""
    });

    function getToday() {
        const today = new Date();
        const yyyy = today.getFullYear();
        const mm = String(today.getMonth() + 1).padStart(2, '0');
        const dd = String(today.getDate()).padStart(2, '0');
        return `${yyyy}-${mm}-${dd}`;
    }

    function search() {
        let sql = 'SELECT * FROM forms WHERE 1';
        let params = [];

        if (sbValues.name) {
            sql += ' AND patient LIKE ?';
            params.push(`%${sbValues.name}%`);
        }
        if (sbValues.sdate || sbValues.edate) {
            sql += ' AND date BETWEEN ? AND ?';

            params.push(sbValues.sdate ? sbValues.sdate : getToday());
            params.push(sbValues.edate ? sbValues.edate : getToday());
        }
        sql += ' ORDER BY date LIMIT 50;';
        queryFunc(sql, params);
    }
</script>

<!-- Primera fila para la barra de búsqueda -->
<div class="flex flex-col md:flex-row gap-x-4 px-4 lg:px-8 py-3 justify-center">
    <div class="w-full max-w-200">
        <label for="sbname">Nombre del paciente:</label>
        <div class="flex">
            <input class="w-full rounded border border-gray-300 px-4 py-2" id="sbname" name="sbname" 
                type="text" maxlength="20" placeholder="Buscar..." bind:value={sbValues.name}/>
            <button class="h-min cursor-pointer rounded-lg border border-black bg-wine text-white transition hover:bg-lightwine active:bg-lightwine px-4 py-2"
                onclick={search}>
                <Icon type="Search" class="w-6 h-6"/>
            </button>
        </div>
    </div>
    <div class="flex flex-row gap-4 flex-1">
        <div class="flex flex-col flex-1">
            <label for="sbsdate">Desde:</label>
            <input class="w-full rounded" type="date" id="sbsdate" name="sbsdate" bind:value={sbValues.sdate}/>
        </div>
        <div class="flex flex-col flex-1">
            <label for="sbedate">Hasta:</label>
            <input class="w-full rounded" type="date" id="sbedate" name="sbedate" bind:value={sbValues.edate}/>
        </div>
    </div>
</div>