<script>
    import { createEventDispatcher } from "svelte";
    export let field;
    export let fieldValue;
    export let fieldIdx = "";
    export let errorValue;
    export let disabled = false;
    let fieldName = field.name + fieldIdx;

    const dispatch = createEventDispatcher();

	function handleInput(event) {
		dispatch('update', event.target.value);
	}
</script>

<div class={field.className}>
    <label class="block text-gray-700 text-sm font-bold mb-2" for={fieldName}>{field.label}</label>
    <textarea name={fieldName} id={fieldName} value={fieldValue} on:input={handleInput}
        rows={field.rows} disabled={disabled}></textarea>
    <p class="text-red-500">{errorValue}</p>
</div>