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
	import Navbar from '$lib/components/Navbar.svelte';
	import Footer from '$lib/components/Footer.svelte';

	import { Capacitor } from '@capacitor/core';

	import { CapacitorSQLite, SQLiteConnection, SQLiteDBConnection } from '@capacitor-community/sqlite';
	import { STATUSES } from '$lib/Dictionary.svelte';
	import Header from '$lib/components/Header.svelte';

	let showModal = $state(false);
	let forms = $state([]);
	let selectedFormIndex = $state(null);
	let logged_in = $state(false);
	let modal = $state(undefined);
	let formRenderer = $state(undefined);
	
	const almacenamiento_formularios = 'firefighter_forms_db';

	let db;

	async function connect_db() {
		// En el navegador web carecemos de almacenamiento persistente, entonces simplemente nos hacemos a la idea de que funciona...
		if (Capacitor.getPlatform() === 'web') {
			return {
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
			return db_func;
		}
	}

	// Inicializar la base de datos
	async function init_db() {
		await db.execute(`
			CREATE TABLE IF NOT EXISTS forms (
				id INTEGER PRIMARY KEY AUTOINCREMENT,
				date TEXT NOT NULL,
				filler TEXT NOT NULL,
				patient TEXT NOT NULL,
				status INTEGER NOT NULL,
				data TEXT NOT NULL
			)
		`);
	}

	// Guardar formulario en la base de datos local
	async function save_form(form) {
		const dataJson = JSON.stringify(form.data);

		// Si ya existe el formulario, se actualiza.
		if (!isNaN(form.id)) {
			await db.run(
				`UPDATE forms SET date = ?, filler = ?, patient = ?, status = ?, data = ? WHERE id = ?`,
				[form.date, form.filler, form.patient, form.status, dataJson, form.id]
			);
			forms[forms.findIndex(f => f.id === form.id)] = form;
		}
		// Si no, se crea.
		else {
			form.id = forms.length;
			await db.run(
				`INSERT INTO forms (date, filler, patient, status, data) VALUES (?, ?, ?, ?, ?)`,
				[form.date, form.filler, form.patient, form.status, dataJson]
			);
			forms.unshift(form);
		}

		showModal = false;
	}

	// Cargar los formularios desde memoria
	async function load_forms() {
		const res = await db.query('SELECT * FROM forms ORDER BY date DESC');
		forms = res.values.map(f => ({
			id: f.id,
			date: f.date,
			filler: f.filler,
			patient: f.patient,
			status: f.status,
			data: JSON.parse(f.data)
		}));
	}

	// Eliminar formulario seleccionado
	async function delete_form(index) {
		await db.run('DELETE FROM forms WHERE id = ?', [forms[index].id])
		forms = forms.toSpliced(index, 1);
		selectedFormIndex = null;
	}

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
		db = await connect_db();
		await init_db();
		await load_forms();
	});
</script>

<Navbar/>
{#if !logged_in}
	<!-- Pantalla de bienvenida que se muestra antes de iniciar sesión -->
	<WelcomeScreen
		on:login={() => {
			logged_in = true;
		}}
	/>
{:else}
<Header></Header>
	<!-- Lista de formularios cargados -->
	<FormsList bind:forms bind:selectedFormIndex={selectedFormIndex} bind:showModal bind:modal on:delete={(e) => delete_form(e.detail.index)}/>
	
	<div class="flex w-full place-items-center justify-center">
		<!-- Botón para añadir un formulario -->
		<Button
			onclick={() => {
				selectedFormIndex = null;
				showModal = true;
			}}
			text="+"
			class="fixed bottom-10 right-6 w-16 h-16 cursor-pointer rounded-full border border-black bg-bronze text-lg text-white transition hover:bg-wine"
		/>
	</div>

	<Modal bind:showModal allowpdf={selectedFormIndex && forms[selectedFormIndex].status == STATUSES.FINISHED} bind:this={modal} bind:formRenderer>
		{#snippet header()}
			<h2 class="text-charcoal-gray">Nuevo Fomulario</h2>
		{/snippet}
		
		{#snippet children()}
			{#if selectedFormIndex && forms[selectedFormIndex].status == STATUSES.FINISHED}
				<PdfPreview formData={forms[selectedFormIndex]}/>
			{:else}
				<FormRenderer template={formulario} bind:this={formRenderer} formData={forms[selectedFormIndex]} on:submit={(e) => save_form(e.detail)}/>
			{/if}
		{/snippet}
	</Modal>
{/if}
<Footer/>

<svelte:head>
	<title>
		Formato de Atención Médica Digital
	</title>
</svelte:head>