<script>
	import jsPDF from 'jspdf';
	import html2canvas from 'html2canvas-pro'; // Esto debería solucionar el error de oklch que mencionaba Brandon.
	import { generateFormPDF } from './forms/PDFMaker';
	let { showModal = $bindable(), header, children, allowpdf, formRenderer = $bindable() } = $props();
	let modalContent;
	let hide = $state(false);
	let modalRef;

	function openModal() {
		showModal = true;
	}

	function closeModal() {
		showModal = false;
		if (modalRef) {
			modalRef.scrollTop = 0;
		}
	}

	async function generatePdf() {
		const overlay = document.getElementById('overlay');
		const spinner = document.getElementById('spinner');

		overlay.style.zIndex = '60';
		spinner.style.display = 'block';

		await generateFormPDF(formRenderer.template, $state.snapshot(formRenderer.formData), false);

		overlay.style.zIndex = '50';
		spinner.style.display = 'none';
	}

	async function callPdf() {
		hide = true;
		await openModal();
		await generatePdf();
		closeModal();
		hide = false;
	}

	export { callPdf };

	let showWarning = $state(false);

	function confirm() {
		showWarning = false;
		closeModal();
	}

	function cancel() {
		showWarning = false;
	}

	function back() {
		if ( formRenderer.localFormData && formRenderer.formData && JSON.stringify($state.snapshot(formRenderer.localFormData)) !== JSON.stringify($state.snapshot(formRenderer.formData))) {
			showWarning = true
		} else {
			closeModal();
		}
	}
</script>

<!-- Overlay -->
<div
	id="overlay" class={`fixed inset-0 z-50 bg-black/30 ${showModal ? 'block' : 'hidden'}`}
></div>

<!-- Loading Icon -->
<div id="spinner" class={`spinner fixed top-1/2 left-1/2 z-60 ${hide ? 'block' : 'hidden'}`}></div>

<!-- Modal con 'div' en lugar de 'dialog' por necesidad al descargar pdf desde la tabla-->
<div
	bind:this={modalRef}
	class={`fixed ${hide ? 'top-9999' : ''} inset-0 z-50 h-full overflow-y-auto bg-white p-0 shadow-lg ${showModal ? 'block' : 'hidden'}`}
>
	<div class="flex justify-between px-4 pb-4 sticky top-0 bg-gray-100 z-70">
		<button
			onclick={ allowpdf ? closeModal : back}
			class="mt-4 block cursor-pointer rounded px-4 py-2 bg-bronze text-white transition hover:bg-wine"
		>
			Regresar
		</button>

		<div class="mt-4 block px-4 py-2 font-bold">
			{@render header?.()}
		</div>

		{#if allowpdf}
			<button
				onclick={generatePdf}
				class="mt-4 block cursor-pointer rounded bg-bronze px-4 py-2 text-white transition hover:bg-blue-600"
			>
				Descargar
			</button>
		{:else}
			<div></div>
		{/if}
	</div>
	<div bind:this={modalContent}>
		{#key showModal}
			{@render children?.()}
		{/key}
	</div>
</div>


<!-- Mensaje de aviso -->
{#if showWarning}
  <div class="fixed inset-0 flex items-center justify-center bg-black/50 z-50">
    <div class="bg-white rounded-lg shadow-lg p-6 max-w-sm w-full">
      <p class="mb-4 text-gray-800">¡Tiene cambios sin guardar!</p>
      <div class="flex justify-end gap-2">
        <button onclick={cancel} class="px-4 py-2 bg-gray-300 rounded hover:bg-gray-400">Cancelar</button>
        <button onclick={confirm} class="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600">Salir</button>
      </div>
    </div>
  </div>
{/if}

<style>
	@keyframes zoom {
		from {
			transform: scale(0.95);
		}
		to {
			transform: scale(1);
		}
	}

	.modal {
		animation: zoom 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
		max-height: 90%;
		overflow-y: auto;
	}

	.spinner {
		border: 4px solid #f3f3f3;
		border-top: 4px solid #3498db;
		border-radius: 50%;
		width: 30px;
		height: 30px;
		animation: spin 1s linear infinite;
		margin: auto;
	}

	@keyframes spin {
		0% {
			transform: rotate(0deg);
		}
		100% {
			transform: rotate(360deg);
		}
	}
</style>
