<!-- +page.svelte -->
<script>
	import WelcomeScreen from '$lib/components/WelcomeScreen.svelte';
	import FormsList from '$lib/components/FormsList.svelte';
	import Button from '$lib/components/Button.svelte';

	import { Preferences } from '@capacitor/preferences';
	import { onMount } from 'svelte';
	import FormRenderer from '$lib/components/forms/FormRenderer.svelte';
	//import formulario from '../lib/components/forms/formulario.json';
	import formulario from './form/campos.json'
	import Modal from '../lib/components/Modal.svelte';
	import PdfPreview from '$lib/components/PdfPreview.svelte';

	let showModal = $state(false);
	let forms = $state(undefined);
	let selectedForm = $state(undefined);
	let logged_in = $state(false);
	let modal = $state(undefined);
	let formRenderer = $state(undefined);

	// Función para guardar un objeto en almacenamiento persistente
	async function set_object(k, v) {
		await Preferences.set({
			key: k,
			value: JSON.stringify(v)
		});
	}

	// Función para recuperar un objeto desde el almacenamiento
	async function get_object(k) {
		return JSON.parse((await Preferences.get({ key: k })).value);
	}

	// Se ejecuta al montar el componente, recuperando los formularios guardados
	onMount(async () => {
		forms = await get_object('forms');
		if (!forms) forms = [];
	});

	function saveForm(data) {
		if (selectedForm) {
			const index = forms.findIndex(f => f.date === selectedForm.date);
			forms[index] = data;
		} else {
			forms.push(data);
		}
		showModal = false;
		// Reemplazar por sqlite
		// set_object("forms", forms);
	}
</script>

{#if !logged_in}
	<!-- Pantalla de bienvenida que se muestra antes de iniciar sesión -->
	<WelcomeScreen
		on:login={() => {
			logged_in = true;
		}}
	/>
{:else}
	<!-- Lista de formularios cargados -->
	<FormsList bind:forms bind:selectedDoc={selectedForm} bind:showModal bind:modal />
	
	<div class="flex w-full place-items-center justify-center">
		<!-- Botón para añadir un formulario de prueba -->
		<Button
			onclick={() => {
				selectedForm = undefined;
				showModal = true;
			}}
			text="Añadir registro"
			class="w-min cursor-pointer rounded-lg border border-black bg-red-500 px-6 py-2 text-white"
		/>
	</div>

	<Modal bind:showModal allowpdf={selectedForm && selectedForm.status == "Completado"} bind:this={modal} bind:formRenderer>
		{#snippet header()}
		<!-- folio? -->
			<h2>Nuevo Fomulario</h2> 
		{/snippet}
		
		{#snippet children()}
			{#if selectedForm && selectedForm.status == "Completado"}
				<PdfPreview formData={selectedForm}/>
			{:else}
				<FormRenderer template={formulario} bind:this={formRenderer} formData={selectedForm} on:submit={e => saveForm(e.detail)}/>
			{/if}
		{/snippet}
	</Modal>
{/if}
