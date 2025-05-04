<script>
	import { onMount } from "svelte";
    import Button from "../Button.svelte";
    import FormTextarea from "$lib/components/forms/FormTextarea.svelte";
	import { createEventDispatcher } from "svelte";
	import FormError from "./FormError.svelte";

	const dispatch = createEventDispatcher();
	export let field;
	export let dataURL = "";
	export let firmado = false;
	export let errorValue;


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
		signaturePad.clear(); // optional: clear existing content
	}

    onMount(async () => {
		const { default: SignaturePad } = await import('signature_pad');
		signaturePad = new SignaturePad(canvas, {
			backgroundColor: "rgba(1,1,1,.05)", 
			penColor: "black"
		});
		window.addEventListener('resize', resizeCanvas);
  		resizeCanvas();
		dispatch("update", "");
	});
	function borrarFirma() {
		signaturePad.clear();
		dispatch("update", "");
		firmado = false;
		message = "";
		signaturePad.on()
		 
	}

	function guardarFirma() {
		if (signaturePad.isEmpty()) { // no deja guardar si no hay firma
			message = "Es necesario firmar antes de guardar.";
			firmado = false;
		} else {
			dataURL = signaturePad.toDataURL('image/png');
			message = "Firmado.";
			firmado = true;
			dispatch("update", dataURL);
			signaturePad.off() // bloquea el canvas caundo se guarda la firma

		}
	}




</script>

<div class={field.className}>
	<p class="block text-gray-700 text-sm font-bold mb-2">{field.label}
		<span class="text-red-500">*</span>
	</p>
    <p class ="text-gray-700">{field.declaracion}</p>

	<div class="border border-gray-600 rounded-md overflow-hidden canvas-wrapper">
		<canvas
			bind:this={canvas}
			width="600"
			height="200"
		></canvas>
	</div>
    <p class ="text-gray-700">{field.nombreLabel}</p>

	<div class="flex space-x-2 mt-2">
		<Button 
		class="mt-4 block cursor-pointer rounded bg-red-500 px-4 py-2 text-white transition hover:bg-red-600 mx-8"
		 onclick={borrarFirma} 
		 text="Borrar"
		 />
		 <Button 
		class="mt-4 block cursor-pointer rounded bg-green-500 px-4 py-2 text-white transition hover:bg-green-600 mx-8"
		onclick={guardarFirma}
		 text="Guardar"
		 />
	</div>
	<FormError errorValue/>
	{#if message}
	<p class={firmado ? "text-green-500" : "text-red-500"}>{message}</p>
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