<script>
    let {
        text = "Click",
        class: classes = "w-min px-6 py-2 rounded-lg cursor-pointer border border-black bg-blue-500 text-white",
        onclick = () => {},
        preventDefault = true
    } = $props();
</script>

<button class={classes} onclick={
    (e) => {
        if (preventDefault) e.preventDefault();
        onclick();
    }
}>
    {text}
</button>