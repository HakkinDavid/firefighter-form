<script>
    import { createEventDispatcher } from "svelte";
	import FormError from "./FormError.svelte";
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
    <label class="block text-charcoal-gray text-sm font-bold mb-2" for={fieldName}>{field.label}</label>
    <textarea name={fieldName} id={fieldName} value={fieldValue} on:input={handleInput}
        rows={field.rows} disabled={disabled} class="mt-1 block w-full"></textarea>
    <FormError bind:errorValue/>
</div>