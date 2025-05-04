<script>
    let {
        errorValue = $bindable()
    } = $props();
</script>
{#if errorValue}
    <p class="text-red-500 whitespace-pre-line">{typeof errorValue === 'object' ? errorValue.join("\n") : errorValue}</p>
{/if}