<script>
    let { 
        message = "", 
        Accept = () => {},
        AcceptLabel = "Aceptar", 
        Cancel = () => {showDialog = false},
        CancelLabel = "Cancelar",
        showDialog = $bindable(false)
    } = $props();
</script>

{#if showDialog}
  <div class="fixed inset-0 flex items-center justify-center bg-black/50 z-100">
    <div class="bg-white rounded-lg shadow-lg p-6 max-w-sm w-full">
      <p class="mb-4 text-gray-800">{message}</p>
      <div class="flex justify-end gap-2">
        <button onclick={Cancel} class="px-4 py-2 bg-gray-300 rounded hover:bg-gray-400 active:bg-gray-400 hover:cursor-pointer">
            {CancelLabel}
        </button>
        <button onclick={Accept} class="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600 active:bg-blue-600 hover:cursor-pointer">
            {AcceptLabel}
        </button>
      </div>
    </div>
  </div>
{/if}