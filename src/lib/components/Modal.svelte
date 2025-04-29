<script>
	import jsPDF from 'jspdf';
	import html2canvas from 'html2canvas';
	let { showModal = $bindable(), header, children, allowpdf } = $props();
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
		const canvas = await html2canvas(modalContent, {
			scrollY: -window.scrollY, //captura el contenido completo sin depender del scroll
			windowHeight: modalContent.scrollHeight //ajusta la altura para capturar todo
		});

		const imgData = canvas.toDataURL('image/png');
		console.log(canvas.width, canvas.height);

		const pdf = new jsPDF({
			orientation: 'p', // "p" para vertical, "l" para horizontal
			unit: 'mm',
			format: 'a4'
		});

		const imgWidth = 150;
		const imgHeight = (canvas.height * imgWidth) / canvas.width; // Mantiene proporciones

		const pageWidth = pdf.internal.pageSize.width;
		const centerX = (pageWidth - imgWidth) / 2;

		pdf.addImage(imgData, 'PNG', centerX, 10, imgWidth, imgHeight);
		pdf.save(`archivo.pdf`);
	}

	async function callPdf() {
		hide = true;
		await openModal();
		await generatePdf();
		closeModal();
		hide = false;
	}

	export { callPdf }
</script>

<!-- Overlay -->
<div
	class={`fixed inset-0 z-50 bg-black/30 ${showModal ? 'block' : 'hidden'}`}
	onclick={closeModal}
></div>

<!-- Loading Icon -->
<div class={`spinner fixed top-1/2 left-1/2 z-60 ${hide ? 'block' : 'hidden'}`}></div>

<!-- Modal con 'div' en lugar de 'dialog' por necesidad al descargar pdf desde la tabla-->
<div bind:this={modalRef}
	class={`fixed inset-0 z-50 rounded-md bg-white p-4 shadow-lg overflow-y-auto h-full ${showModal ? 'block' : 'hidden'}`}
>
	<div bind:this={modalContent}>
		
		<div class="flex justify-between">
			<button
				onclick={closeModal}
				class="mt-4 block cursor-pointer rounded bg-blue-500 px-4 py-2 text-white transition hover:bg-blue-600"
			>
				Cerrar
			</button>
			{#if allowpdf}
				<button
					onclick={generatePdf}
					class="mt-4 block cursor-pointer rounded bg-blue-500 px-4 py-2 text-white transition hover:bg-blue-600"
				>
					Descargar pdf
				</button>
			{/if}
			{@render header?.()}
		</div>
		<hr class="my-2" />
		{#key showModal}
			{@render children?.()}
		{/key}
	</div>

</div>

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
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }
</style>
