<!-- FormsList.svelte -->
<script>
	import Icon from '$lib/components/Icon.svelte';
	import { stopPropagation } from 'svelte/legacy';
	import Modal from './Modal.svelte';

	let {
		forms = $bindable([]), // Lista de formularios vinculada al estado
		selectedDoc = $bindable(undefined),
		showModal = $bindable(false)
	} = $props();

	function deleteDoc(index) {
		forms = forms.toSpliced(index, 1);
	}

	function selectDoc(form) {
		selectedDoc = form;
		showModal = true;
	}

	let modalContent;
	function generatePdf(form) {
		selectedDoc = form;
		modalContent.callPdf();
	}

</script>

<!-- Tabla que muestra la lista de formularios -->
<div class="flex h-full w-full px-8 py-3">
	<table class="h-full w-full border-2 border-black text-center">
		<thead>
			<tr>
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
					class="cursor-pointer place-items-center justify-center border border-black transition hover:bg-gray-200"
					onclick={() => selectDoc(form)}
				>
					<td>{form.date?.toLocaleString()}</td>
					<td>{form.filler}</td>
					<td>{form.patient}</td>
					<td>{form.status}</td>
					<!-- Iconos para acciones en cada fila -->
					<td
						onclick={(event) => {
							deleteDoc(index);
							event.stopPropagation();
						}}
						class="place-items-center justify-center transition hover:bg-red-300"
						><Icon type="Borrar" class="h-8 w-8 cursor-pointer" /></td
					>
					<td
						onclick={(event) => {
							generatePdf(form);
							event.stopPropagation();
						}}
						class="place-items-center justify-center transition hover:bg-blue-300"
						><Icon type="PDF" class="h-8 w-8 cursor-pointer" /></td
					>
				</tr>
				{/if}
			{/each}
		</tbody>
	</table>
</div>
