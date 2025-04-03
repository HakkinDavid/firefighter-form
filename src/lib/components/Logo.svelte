<script>
    import Tijuana from "$lib/components/Tijuana.svelte";
    let { type, class: classes = "w-16 h-16" } = $props();
</script>

<div class={classes + "flex place-content-center justify-center"}>
    {#if type === "Tijuana"}
        <Tijuana />
    {:else if type === "Bomberos"}
        <!-- svelte-ignore a11y_missing_attribute -->
        <img src="/bomberos.png" class="w-full h-full">
    {/if}
</div>