<!-- FormsList.svelte -->
<script>
	import Icon from '$lib/components/Icon.svelte';
	import { stopPropagation } from 'svelte/legacy';
	import PDFModal from './PDFModal.svelte';
	import { FORM_STATUSES } from '$lib/Dictionary.svelte';
	import { createEventDispatcher } from 'svelte';

	let dispatch = createEventDispatcher();

	let {
		forms = $bindable([]), // Lista de formularios vinculada al estado
		selectedFormIndex = $bindable(null),
		showModal = $bindable(false),
		pdfModal
	} = $props();

	function deleteDoc(index) {
		dispatch('delete', {index});
	}

	function selectDoc(index) {
		selectedFormIndex = index;
		showModal = true;
	}


	function generatePdf(index) {
		selectedFormIndex = index;
		pdfModal.callPdf();
	}

</script>

<!-- Tabla que muestra la lista de formularios -->
<div class="flex h-full w-full text-xs sm:text-sm lg:px-8 py-3 text-wrap">
	<table class="h-full w-full border-2 border-black text-center">
		<thead class="bg-crimson">
			<tr class="text-white">
				<th>ID</th>
				<th>Fecha</th>
				<th>Responsable</th>
				<th>Paciente</th>
				<th>Estado</th>
				<th><pre></pre></th>
				<th><pre></pre></th>
			</tr>
		</thead>
		<tbody>
			{#each forms as form, index}
				{#if form}
				<tr
					class="text-charcoal-gray cursor-pointer place-items-center justify-center border border-black transition hover:bg-gray-200"
					onclick={() => selectDoc(index)}
				>
					<td>{form.id}</td>
					<td>{form.date.split("-").reverse().join("/")}</td>
					<td>{form.filler}</td>
					<td>{form.patient}</td>
					<td>{FORM_STATUSES[form.status]}</td>
					<!-- Iconos para acciones en cada fila -->
					<td
						colspan={form.status == FORM_STATUSES.DRAFT ? 2 : 1}
						onclick={(event) => {
							deleteDoc(index);
							event.stopPropagation();
						}}
						class="place-items-center justify-center transition hover:bg-red-300"
						><Icon type="Borrar" class="h-8 w-8 cursor-pointer" /></td
					>
					{#if form.status == FORM_STATUSES.FINISHED}
						<td
							onclick={(event) => {
								generatePdf(index);
								event.stopPropagation();
							}}
							class="place-items-center justify-center transition hover:bg-blue-300"
							><Icon type="PDF" class="h-8 w-8 cursor-pointer" /></td
						>
					{/if}
				</tr>
				{/if}
			{/each}
		</tbody>
	</table>
</div>
