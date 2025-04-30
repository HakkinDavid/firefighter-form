<!-- +page.svelte -->
<script>
	import WelcomeScreen from '$lib/components/WelcomeScreen.svelte';
	import FormsList from '$lib/components/FormsList.svelte';
	import Button from '$lib/components/Button.svelte';

	import { Preferences } from '@capacitor/preferences';
	import { onMount } from 'svelte';
	// Esto es temporal, después se moverá de lugar
	import FormRenderer from '$lib/components/forms/FormRenderer.svelte';
	//import formulario from '../lib/components/forms/formulario.json';
	import formulario from './form/campos.json'
	import Modal from '../lib/components/Modal.svelte';
	let showModal = $state(false);

	let forms = $state(undefined);
	let logged_in = $state(false);

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
</script>

{#if !logged_in}
	<!-- Pantalla de bienvenida que se muestra antes de iniciar sesión -->
	<WelcomeScreen
		on:login={() => {
			logged_in = true;
		}}
	/>
{:else}

	<button
		class="mt-4 block cursor-pointer rounded bg-blue-500 px-4 py-2 text-white transition hover:bg-blue-600 mx-8"
		onclick={() => {
			showModal = true;
		}}
	>
		Crear Nuevo
	</button>
	<!-- Lista de formularios cargados -->
	<FormsList bind:forms />
	
	<div class="flex w-full place-items-center justify-center">
		<!-- Botón para añadir un formulario de prueba -->
		<Button
			onclick={() => {
				forms.push({
					date: new Date(),
					filler: {
						name: 'Bombero Prueba'
					},
					patient: {
						name: 'Paciente Prueba'
					},
					status: 'Completo'
				});
			}}
			text="Añadir registro de prueba"
			class="w-min cursor-pointer rounded-lg border border-black bg-red-500 px-6 py-2 text-white"
		/>
	</div>

	<Modal bind:showModal allowpdf={false}>
		{#snippet header()}
		<!-- folio? -->
			<h2>Nuevo Fomulario</h2> 
		{/snippet}

		<FormRenderer template={formulario} />
	</Modal>
{/if}
