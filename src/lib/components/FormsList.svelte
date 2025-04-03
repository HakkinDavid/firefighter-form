<script>
	import Icon from "$lib/components/Icon.svelte";

    let {
        forms = $bindable([])
    } = $props();
</script>

<div class="flex w-full h-full px-8 py-16">
    <table class="w-full h-full border-2 border-black text-center">
        <thead>
            <tr>
              <th>Fecha</th>
              <th>Responsable</th>
              <th>Paciente</th>
              <th>Estado</th>
              <th><pre>    </pre></th>
              <th><pre>    </pre></th>
            </tr>
        </thead>
        <tbody>
            {#each forms as form}
                <tr class="border border-black place-items-center justify-center">
                    <td class="place-items-center justify-center">{form.date.toLocaleString()}</td>
                    <td class="place-items-center justify-center">{form.filler.name}</td>
                    <td class="place-items-center justify-center">{form.patient.name}</td>
                    <td class="place-items-center justify-center">{form.status}</td>
                    <td class="place-items-center justify-center">
                        <Icon type="Borrar" class="w-8 h-8"/>
                    </td>
                    <td class="place-items-center justify-center">
                        <Icon type="PDF" class="w-8 h-8"/>
                    </td>
                </tr>
            {/each}
        </tbody>
    </table>
</div>