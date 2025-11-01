<script>
  import { dialog } from "$lib/stores/dialogStore.svelte.js"
</script>

{#if dialog.content}
  <div class="fixed inset-0 flex items-center justify-center bg-black/50 z-100">
    <div class="bg-white rounded-lg shadow-lg p-6 max-w-sm w-full">
      <p class="font-bold">{dialog.content.title}</p>
      <p class="mb-4 text-gray-800">{dialog.content.message}</p>
      <div class="flex justify-end gap-2">
        <button onclick={() => { dialog.content.Cancel?.(); dialog.close(); }} 
          class="px-4 py-2 bg-gray-300 rounded hover:bg-gray-400 active:bg-gray-400 hover:cursor-pointer">
          {dialog.content.CancelLabel ?? "Cancelar"}
        </button>
        <button onclick={() => { dialog.content.Accept?.(); dialog.close(); }} 
          class="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600 active:bg-blue-600 hover:cursor-pointer">
          {dialog.content.AcceptLabel ?? "Aceptar"}
        </button>
      </div>
    </div>
  </div>
{/if}