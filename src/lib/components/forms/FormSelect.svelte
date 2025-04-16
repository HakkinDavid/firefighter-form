<script>
    import { createEventDispatcher } from "svelte";
    export let field;
    export let fieldValue;
    export let errorValue;
    export let disabled = false;

    const dispatch = createEventDispatcher();

	function handleInput(event) {
		dispatch('update', event.target.value);
	}
</script>

<div class={field.className}>
    <label class="block text-gray-700 text-sm font-bold mb-2" for={field.name}>{field.label}</label>
    <select id={field.name} name={field.name} value={fieldValue} on:input={handleInput}>
        <option value="" disabled={disabled}>Seleccione una opción</option>
        {#each field.options as option}
            <option value={option}>{option}</option>
        {/each}
    </select>
    <p class="text-red-500">{errorValue}</p>
</div>