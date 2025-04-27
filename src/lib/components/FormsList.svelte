<!-- FormsList.svelte -->
<script>
	import Icon from '$lib/components/Icon.svelte';
	import { stopPropagation } from 'svelte/legacy';
	import Modal from './Modal.svelte';

	let showModal = $state(false);
	let selectedDoc = $state(null);

	let {
		forms = $bindable([]) // Lista de formularios vinculada al estado
	} = $props();

	function deleteDoc(index) {
		forms = forms.toSpliced(index, 1);
	}

	function selectDoc(form) {
		selectedDoc = form;
		showModal = true;
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
				<tr
					class="cursor-pointer place-items-center justify-center border border-black transition hover:bg-gray-200"
					onclick={() => selectDoc(form)}
				>
					<td>{form.date.toLocaleString()}</td>
					<td>{form.filler.name}</td>
					<td>{form.patient.name}</td>
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
					<!--
					<td
						onclick={(event) => {
							generatePdf(form);
							event.stopPropagation();
						}}
						class="place-items-center justify-center"
						><Icon type="PDF" class="h-8 w-8 cursor-pointer" /></td
					>
					-->
				</tr>
			{/each}
		</tbody>
	</table>
</div>

<!--Aqui solo cambiamos la variable allowpdf para mostrar o no mostrar el botón de descarga-->
<Modal bind:showModal allowpdf={true}>
	{#snippet header()}
		<h2>
			{selectedDoc && `Formulario de ${selectedDoc.patient.name}`}
		</h2>
	{/snippet}

	{#if selectedDoc}
		<!--Esto se modifica para mostrar la información con base en el template cuando ya se guarde adecuadamente en la tabla-->
		<p>Fecha de creación: {selectedDoc.date}</p>
		<p>Atiende: {selectedDoc.filler.name}</p>
		<p>Paciente: {selectedDoc.patient.name}</p>
		<p>Estado: {selectedDoc.status}</p>
	{/if}
</Modal>
