<!-- +page.svelte -->
<script>
	import WelcomeScreen from '$lib/components/WelcomeScreen.svelte';
	import FormsList from '$lib/components/FormsList.svelte';
	import Button from '$lib/components/Button.svelte';

	import { Preferences } from '@capacitor/preferences';
	import { onMount } from 'svelte';
	import FormRenderer from '$lib/components/forms/FormRenderer.svelte';
	import formulario from './form/campos.json'
	import PDFModal from '../lib/components/PDFModal.svelte';
	import AdminModal from '$lib/components/settings/AdminModal.svelte';
	import PdfPreview from '$lib/components/PdfPreview.svelte';
	import Navbar from '$lib/components/Navbar.svelte';
	import Footer from '$lib/components/Footer.svelte';

	import { Capacitor } from '@capacitor/core';
	import { App } from '@capacitor/app';

	import { FORM_STATUSES, NOTICE_TYPES, ACTION_STATUSES } from '$lib/Dictionary.svelte';
	import { connect_db, get_db, init_db } from '$lib/db/sqliteConfig';

	let showModal = $state(false);
	let forms = $state([]);
	let selectedFormIndex = $state(null);
	let logged_in = $state(false);
	let admin_modal;
	let admin_modal_reject = $state(() => {});
	let admin_modal_authorize = $state(() => {});
	let pdfModal = $state(undefined);
	let formRenderer = $state(undefined);
	let settings = $state({});
	let was_admin_registered = $state(true);
	
	const CURRENT_PLATFORM = Capacitor.getPlatform();
	let db;

	// Guardar formulario en la base de datos local
	async function save_form(form) {
		const dataJson = JSON.stringify(form.data);

		// Si ya existe el formulario, se actualiza.
		if ((await db.query('SELECT * FROM forms WHERE id = ?', [form.id])).values.length > 0) {
			await db.run(
				`UPDATE forms SET date = ?, filler = ?, patient = ?, status = ?, data = ? WHERE id = ?`,
				[form.date, form.filler, form.patient, form.status, dataJson, form.id]
			);
			forms[forms.findIndex(f => f.id === form.id)] = form;
		}
		// Si no, se crea.
		else {
			await db.run(
				`INSERT INTO forms (date, filler, patient, status, data) VALUES (?, ?, ?, ?, ?)`,
				[form.date, form.filler, form.patient, form.status, dataJson]
			);
			form.id = (await db.query("select seq from sqlite_sequence where name=\"forms\"")).values[0].seq;
			forms.unshift(form);
		}

		showModal = false;
	}

	// Cargar los formularios desde memoria
	async function load_forms() {
		const res = await db.query('SELECT * FROM forms ORDER BY id DESC');
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
		admin_modal_authorize = async () => {
			await db.run('DELETE FROM forms WHERE id = ?', [forms[index].id])
			forms = forms.toSpliced(index, 1);
			selectedFormIndex = null;
		}
		admin_modal.open();
	}

	async function load_settings() {
		if (CURRENT_PLATFORM === 'web') {
			settings = await get_object('settings');
			if (!settings) settings = {};
		}
		const current_settings = await db.query('SELECT * FROM settings ORDER BY key DESC');

		current_settings.values.forEach(setting_row => {
			settings[setting_row.key] = setting_row.value;
		});
	}

	async function save_settings(include_sensitive = false) {
		if (CURRENT_PLATFORM === 'web') {
			await set_object('settings', settings);
		}
		for (const s in settings) {
			switch (s) {
				case "admin_username":
				case "admin_password":
					if (!include_sensitive) {
						console.log("Saltando configuración: " + s);
						continue;
					}
					else {
						console.warn("Guardando configuración: " + s);
					}
				break;
				default:
					console.log("Guardando configuración: " + s);
				break;
			}
			if ((await db.query('SELECT * FROM settings WHERE key = ?', [s])).values.length > 0) {
				await db.run(`UPDATE settings SET value = ? WHERE key = ?`, [settings[s], s]);
			}
			else {
				await db.run(`INSERT INTO settings (key, value) VALUES (?, ?)`, [s, settings[s]]);
			}
		}
	}

	async function attempt_admin_register () {
		if (was_admin_registered || !settings || !settings.admin_username || !settings.admin_password) {
			if (CURRENT_PLATFORM === 'web') {
				console.error("Simulando cierre...");
				window.location.reload();
			}
			App.exitApp();
			return;
		}
		else {
			await save_settings(true);
			was_admin_registered = true;
		}
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

	function reset_admin_modal () {
		admin_modal_reject = () => {
			console.warn("Se negó la autorización del supervisor sin algún comportamiento definido.");
		}
		admin_modal_authorize = () => {
			console.warn("Se concedió la autorización del supervisor sin algún comportamiento definido.");
		}
	}

	// Se ejecuta al montar el componente, recuperando los formularios guardados
	onMount(async () => {
		await connect_db(CURRENT_PLATFORM);
		db = get_db();
		await init_db();
		await load_settings();
		reset_admin_modal();

		if (settings && (!settings.admin_username || !settings.admin_password)) {
			was_admin_registered = false;
			console.log("No hay datos de administrador establecidos. Solicitando.");
			admin_modal_reject = () => {
				if (CURRENT_PLATFORM === 'web') {
					console.error("Simulando cierre...");
					window.location.reload();
				}
				App.exitApp();
			}
			admin_modal.open(NOTICE_TYPES.INFORMATION, ACTION_STATUSES.SIGN_ADMIN_UP);
		}

		await load_forms();
	});
</script>

{#if was_admin_registered}
	<Navbar username={settings.username} admin_username={settings.admin_username}/>
	{#if !logged_in}
		<!-- Pantalla de bienvenida que se muestra antes de iniciar sesión -->
		<WelcomeScreen
			on:login={() => {
				logged_in = true;
			}}
		/>
	{:else}
		<!-- Lista de formularios cargados -->
		<FormsList bind:forms bind:selectedFormIndex={selectedFormIndex} bind:showModal bind:pdfModal on:delete={(e) => delete_form(e.detail.index)}/>
		
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

		<PDFModal bind:showModal allowpdf={!isNaN(selectedFormIndex) && forms[selectedFormIndex] && forms[selectedFormIndex].status === FORM_STATUSES.FINISHED} bind:this={pdfModal} bind:formRenderer>
			{#snippet header()}
				<h2 class="text-charcoal-gray">Nuevo Fomulario</h2>
			{/snippet}
			
			{#snippet children()}
				{#if !isNaN(selectedFormIndex) && forms[selectedFormIndex] && forms[selectedFormIndex].status === FORM_STATUSES.FINISHED}
					<PdfPreview formData={forms[selectedFormIndex]} template={formulario}/>
				{:else}
					<FormRenderer template={formulario} bind:this={formRenderer} formData={forms[selectedFormIndex]} on:submit={(e) => save_form(e.detail)}/>
				{/if}
			{/snippet}
		</PDFModal>
	{/if}
	<Footer/>
{:else}
<div class="w-screen h-screen bg-black">

</div>
{/if}

<AdminModal bind:this={admin_modal} bind:settings on:registered={attempt_admin_register} on:authorized={admin_modal_authorize} on:cancel={admin_modal_reject} on:close={reset_admin_modal}/>

<svelte:head>
	<title>
		Formato de Atención Médica Digital
	</title>
</svelte:head>