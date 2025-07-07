<script>
	import { onMount, onDestroy, createEventDispatcher } from "svelte";
    import Button from "../Button.svelte";
	import FormError from "./FormError.svelte";
	import SignaturePad from "signature_pad";
	import { isBase64Image } from "./PDFMaker";
	import { DrawingBoardImages } from "./FormImages";
	import { debounce } from "$lib/debounce";

	const dispatch = createEventDispatcher();
	export let field;
	export let fieldValue = "";
	export let errorValue;
	export let disabled = false;

	let modified = false;
	let message = "";
	let canvas;
	let background = DrawingBoardImages[field.background ?? ""];
	let signaturePad;

	function resizeCanvas() {
		if (!canvas) return;
		const content = signaturePad ? signaturePad.toDataURL(): null;
		const ratio = window.devicePixelRatio || 1;
		canvas.width = canvas.offsetWidth * ratio;
		canvas.height = canvas.offsetHeight * ratio;
		canvas.getContext('2d').scale(ratio, ratio);
		if (signaturePad && isBase64Image(content)) {
			signaturePad.clear()
			signaturePad.fromDataURL(content);
		}
	}
	const debouncedResizeFunction = debounce(resizeCanvas, 300);

	function update(str) {
		if (disabled) return;
		dispatch("update", str);
	}

    onMount(async () => {
		if (disabled) return;

		signaturePad = new SignaturePad(canvas, {
			backgroundColor: "rgba(1,1,1,.05)", 
			penColor: "black"
		});
		resizeCanvas();
		window.addEventListener('resize', debouncedResizeFunction);
		signaturePad.clear();

		if (fieldValue) {
			signaturePad.fromDataURL(fieldValue);
			modified = true;
		} else clearCanvas();
	});

	onDestroy(() => {
		if (disabled) return;
		window.removeEventListener('resize', debouncedResizeFunction);
	});

	function clearCanvas() {
		signaturePad.clear();
		if (isBase64Image(background)) {
			signaturePad.fromDataURL(background);
		}
		// Sí se limpia el canvas, no se guarda la imagen del fondo.
		update("");
		modified = false;
		message = "";
		signaturePad.on();
	}

	function saveCanvas() {
		if (signaturePad.isEmpty()) { // no deja guardar si no hay firma
			message = "No hay contenido que guardar."
			modified = false;
		} else {
			fieldValue = signaturePad.toDataURL('image/jpg');
			modified = true;
			message = "Guardado."
			update(fieldValue);
			signaturePad.off() // bloquea el canvas caundo se guarda la firma
		}
	}
</script>

<div class={field.className}>
	<p class="block text-gray-700 text-sm font-bold mb-2">{field.label}
		<span class="text-red-500">*</span>
	</p>
    <p class="text-gray-700 overflow-auto">{field.text}</p>

	<div class="border border-gray-600 rounded-md overflow-hidden canvas-wrapper" 
		style={`aspect-ratio: ${field.aspect_ratio ?? 3}`}>
		{#if disabled}
			<img src = {fieldValue} alt={fieldValue ? "Dibujo o firma." : "No se guardó el contenido."} class="w-full h-full" />
		{:else}
			<canvas
				bind:this={canvas}
			></canvas>
		{/if}
	</div>
    <p class ="text-gray-700">{field.secondaryLabel}</p>

	<div class="flex justify-start gap-2 mt-2" hidden={disabled}>
		<Button 
			class="mt-4 block cursor-pointer rounded bg-red-500 px-4 py-2 text-white transition hover:bg-red-600 active:bg-red-600 mx-4"
			onclick={clearCanvas} 
			text="Borrar"
		/>
		<Button 
			class="mt-4 block cursor-pointer rounded px-4 py-2 bg-bronze text-white transition hover:bg-wine active:bg-wine mx-4"
			onclick={saveCanvas}
			text="Guardar"
		/>
	</div>
	<FormError errorValue={errorValue}/>
	{#if message}
		<p class={modified ? "text-green-500" : "text-red-500"}>{message} </p>
	{/if}


</div>

<style>
	.canvas-wrapper {
		width: 100%;
	}
	.canvas-wrapper canvas {
		width: 100%;
		height: 100%;
		display: block;
	}
</style>