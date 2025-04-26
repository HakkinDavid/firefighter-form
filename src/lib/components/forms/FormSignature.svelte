<script>
	import { onMount } from "svelte";
    import Button from "../Button.svelte";
    import FormTextarea from "$lib/components/forms/FormTextarea.svelte";


	export let field;
    export let declaracion = ""; 
    export let nombreLabel = "";

	let canvas;
	let signaturePad;

    onMount(async () => {
		const { default: SignaturePad } = await import('signature_pad');
		signaturePad = new SignaturePad(canvas, {
			width: 600,
			height: 200,
			backgroundColor: "rgba(255,0,0,.5)", 
			penColor: "black"
		});


	});
	function borrarFirma() {
		signaturePad.clear();
	}


</script>

<div class={field.className} style="width: 600px;">
	<p class="block text-gray-700 text-sm font-bold mb-2">{field.label}
		<span class="text-red-500">*</span>
	</p>
    <p class ="text-gray-700">{field.declaracion}</p>

	<div class="border border-gray-600 rounded-md overflow-hidden">
		<canvas
			bind:this={canvas}
			width="600"
			height="200"
		></canvas>
	</div>
    <p class ="text-gray-700">{field.nombreLabel}</p>

	<div class="flex space-x-2 mt-2">
		<Button text="Borrar Firma" onclick={borrarFirma} />
	</div>
</div>
