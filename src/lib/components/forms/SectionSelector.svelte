<script>
    let colors = ["#EB2C36", "#FF8904", "#228B22", "#0047AB", "#1A2E75", "#6F51E0"];
    let { sections, selected = $bindable(""), isOpen = $bindable(true) } = $props();
</script>

<nav class="sticky top-18 z-50 w-full h-12 bg-slate-100 shadow-md border border-gray-200 overflow-x-auto">
  <div class="flex justify-center items-center h-full min-w-max px-4 space-x-2 mx-auto">
    <button 
        class="text-white rounded px-4 py-2 flex-shrink-0 border border-gray-300 bg-gray-500"
        onclick={() => { selected = ""; }}>
        Todos los campos
    </button>
    {#each sections as section, idx}
      <button 
        class="text-white rounded px-4 py-2 flex-shrink-0 border border-gray-300"
        style={`background-color: ${colors[idx % colors.length]};`}
        onclick={() => { selected = section; }}>
        {section}
      </button>
    {/each}
  </div>
</nav>