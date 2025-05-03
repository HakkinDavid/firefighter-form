<script>
	import { onMount } from "svelte";
    import Button from "../Button.svelte";
    import FormTextarea from "$lib/components/forms/FormTextarea.svelte";
	export let field;

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
	});
	function borrarFirma() {
		signaturePad.clear();
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
		<Button text="Borrar Firma" onclick={borrarFirma} 
		class="w-full py-2 rounded-lg cursor-pointer border border-black bg-bronze text-white transition hover:bg-wine"/>
	</div>
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