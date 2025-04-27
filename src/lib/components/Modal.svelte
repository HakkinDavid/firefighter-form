<script>
	import jsPDF from 'jspdf';
	import html2canvas from 'html2canvas';
	let { showModal = $bindable(), header, children, allowpdf } = $props();
	let modalContent;

	function openModal() {
		showModal = true;
	}

	function closeModal() {
		showModal = false;
	}

	async function generatePdf() {
		const canvas = await html2canvas(modalContent, {
			scrollY: -window.scrollY, //captura el contenido completo sin depender del scroll
			windowHeight: modalContent.scrollHeight //ajusta la altura para capturar todo
		});

		const imgData = canvas.toDataURL('image/png');

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
</script>

<!-- Overlay -->
<div
	class={`fixed inset-0 z-50 bg-black/30 ${showModal ? 'block' : 'hidden'}`}
	onclick={closeModal}
></div>

<!-- Modal con 'div' en lugar de 'dialog' por necesidad al descargar pdf desde la tabla-->
<div
	class={`modal fixed top-1/2 left-1/2 z-50 w-full max-w-lg -translate-x-1/2 -translate-y-1/2 rounded-md bg-white p-4 shadow-lg ${showModal ? 'block' : 'hidden'}`}
>
	<div bind:this={modalContent}>
		{@render header?.()}
		<hr class="my-2" />
		{@render children?.()}
		<hr class="my-2" />
	</div>

	<div>
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
					Pdf
				</button>
			{/if}
		</div>
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
</style>
