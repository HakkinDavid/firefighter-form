<script>
  let colors = ["#EB2C36", "#FF8904", "#228B22", "#0047AB", "#1A2E75", "#6F51E0"];
  let { sections, selected = $bindable(""), isOpen = $bindable(true) } = $props();

  function darkenColor(hex, percent) {
    let num = parseInt(hex.slice(1), 16);
    let r = Math.floor((num >> 16) * (1 - percent));
    let g = Math.floor(((num >> 8) & 0x00FF) * (1 - percent));
    let b = Math.floor((num & 0x0000FF) * (1 - percent));
    return `rgb(${r}, ${g}, ${b})`;
  }
</script>

<nav class="sticky top-18 z-50 w-full h-12 bg-slate-100 shadow-md border border-gray-200 overflow-x-auto">
  <div class="flex justify-center items-center h-full min-w-max px-4 space-x-2 mx-auto">
    <button 
        class={`text-white rounded px-4 py-2 flex-shrink-0 border ${selected === "" ? "border-2 border-black" : "border-gray-300"} bg-gray-500`}
        onclick={() => { selected = ""; }}>
        Todos los campos
    </button>
    {#each sections as section, idx}
    {@const color = colors[idx % colors.length]}
    {@const isSelected = selected === section}
    {@const borderColor = isSelected ? darkenColor(color, 0.25) : "#D1D5DB"}
      <button 
        class="text-white rounded px-4 py-2 flex-shrink-0 border"
        style={`background-color: ${color}; border-color: ${borderColor}; border-width: ${isSelected ? '2px' : '1px'};`}
        onclick={() => { selected = section; }}>
        {section}
      </button>
    {/each}
  </div>
</nav>