<script>
	import { onMount } from "svelte";
    import Button from "../Button.svelte";
    import FormTextarea from "$lib/components/forms/FormTextarea.svelte";
	import { createEventDispatcher } from "svelte";
	import FormError from "./FormError.svelte";

	const dispatch = createEventDispatcher();
	export let field;
	export let fieldValue = "";
	export let firmado = false;
	export let errorValue;
	export let disabled = false;


    let declaracion = ""; 
    let nombreLabel = "";
	let message = "";
	let canvas;
	let signaturePad;

	function resizeCanvas() {
		if (!canvas) return;
		const ratio = window.devicePixelRatio || 1;
		canvas.width = canvas.offsetWidth * ratio;
		canvas.height = canvas.offsetHeight * ratio;
		canvas.getContext('2d').scale(ratio, ratio);
	}

	function update(str) {
		if (disabled) return;
		dispatch("update", str);
	}

    onMount(async () => {
		resizeCanvas();
		const { default: SignaturePad } = await import('signature_pad');
		signaturePad = new SignaturePad(canvas, {
			backgroundColor: "rgba(1,1,1,.05)", 
			penColor: "black"
		});
		signaturePad.clear();
		if (fieldValue) {
			signaturePad.fromDataURL(fieldValue);
			message = "Firmado."
			firmado = true;
			//signaturePad.off();
		}
		else {
			update("");
		}

		if (disabled) {
			signaturePad.off();
		}
	});
	function borrarFirma() {
		signaturePad.clear();
		update("");
		firmado = false;
		message = "";
		signaturePad.on();
	}

	function guardarFirma() {
		if (signaturePad.isEmpty()) { // no deja guardar si no hay firma
			message = "Es necesario firmar antes de guardar.";
			firmado = false;
		} else {
			fieldValue = signaturePad.toDataURL('image/jpg');
			message = "Firmado.";
			firmado = true;
			update(fieldValue);
			signaturePad.off() // bloquea el canvas caundo se guarda la firma

		}
	}
</script>

<div class={field.className}>
	<p class="block text-gray-700 text-sm font-bold mb-2">{field.label}
		<span class="text-red-500">*</span>
	</p>
    <p class="text-gray-700 overflow-auto">{field.declaracion}</p>

	<div class="border border-gray-600 rounded-md overflow-hidden canvas-wrapper">
		{#if disabled}
			<img src = {fieldValue} alt="Firma" class="w-full h-full" />
		{:else}
			<canvas
				bind:this={canvas}
			></canvas>
		{/if}
	</div>
    <p class ="text-gray-700">{field.nombreLabel}</p>

	<div class="flex space-x-2 mt-2" hidden={disabled}>
		<Button 
		class="mt-4 block cursor-pointer rounded bg-red-500 px-4 py-2 text-white transition hover:bg-red-600 mx-8"
		 onclick={borrarFirma} 
		 text="Borrar"
		 />
		 <Button 
		class="mt-4 block cursor-pointer rounded px-4 py-2 bg-bronze text-white transition hover:bg-wine mx-8"
		onclick={guardarFirma}
		 text="Guardar"
		 />
	</div>
	<FormError bind:errorValue/>
	{#if message}
	<p class={firmado ? "text-green-500" : "text-red-500"}>{message} </p>
	{/if}


</div>

<style>
	.canvas-wrapper {
		width: 100%;
		aspect-ratio: 3;
	}
	.canvas-wrapper canvas {
		width: 100%;
		height: 100%;
		display: block;
	}
</style>