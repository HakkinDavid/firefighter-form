<script>
	import { jsPDF } from 'jspdf';
	let { showModal = $bindable(), header, children } = $props();
	let modalContent;

	function openModal() {
		showModal = true;
	}

	function closeModal() {
		showModal = false;
	}

	function generatePdf() {
		const pdf = new jsPDF();

		pdf.setFontSize(14);
		pdf.text(
			'Texto de ejemplo por el momento porque está siendo realmente un desafío guardar el',
			10,
			10
		);
		pdf.text('pdf del modal de manera adecuada...', 10, 20);
		pdf.save('archivo.pdf');
		/*pdf.html(modalContent, {
			callback: function (doc) {
				doc.save('captura.pdf');
			}
		});*/
	}

	export { generatePdf };
</script>

<!-- Overlay -->
<div
	class={`fixed inset-0 z-50 bg-black/30 ${showModal ? 'block' : 'hidden'}`}
	onclick={closeModal}
></div>

<!-- Modal -->
<div
	class={`modal fixed top-1/2 left-1/2 z-50 w-full max-w-lg -translate-x-1/2 -translate-y-1/2 rounded-md bg-white p-4 shadow-lg ${showModal ? 'block' : 'hidden'}`}
>
	<div bind:this={modalContent}>
		{@render header?.()}
		<hr class="my-2" />
		{@render children?.()}
		<hr class="my-2" />

		<button
			onclick={closeModal}
			class="mt-4 block cursor-pointer rounded bg-blue-500 px-4 py-2 text-white transition hover:bg-blue-600"
		>
			Cerrar
		</button>
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
