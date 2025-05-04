<script>
    import { createEventDispatcher } from "svelte";
	import FormError from "./FormError.svelte";
    export let field;
    export let fieldValue;
    export let fieldIdx = "";
    export let errorValue;
    export let disabled = false;
    let fieldName = field.name +  fieldIdx;
    let inputClass = "mt-1 block w-full";

    const dispatch = createEventDispatcher();

	function handleInput(event) {
		dispatch('update', event.target.value);
	}
</script>

<div class={field.className}>
    <label class="block text-charcoal-gray text-sm font-bold mb-2 mt-auto" for={fieldName}>{field.label}</label>
    <select id={fieldName} name={fieldName} value={fieldValue} on:input={handleInput} disabled={disabled} class={inputClass}>
        <option value="">Seleccione una opción</option>
        {#each field.options as option}
            <option value={option}>{option}</option>
        {/each}
    </select>
    <FormError errorValue/>
</div>