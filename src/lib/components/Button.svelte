<!-- Button.svelte -->
<script>
    let {
        text = "Click", // Texto del botón
        class: classes = "w-min px-6 py-2 rounded-lg cursor-pointer border border-black bg-blue-500 text-white", // Clases CSS por defecto
        style: styles = "",
        onclick = () => {}, // Función de clic
        preventDefault = true // Previene la acción por defecto del botón
    } = $props();
</script>

<!-- Botón reutilizable con estilos personalizados y control de eventos -->
<button class={classes} style={styles} onclick={
    (e) => {
        if (preventDefault) e.preventDefault();
        onclick();
    }
}>
    {text}
</button>