<script>
    import { createEventDispatcher } from "svelte";
	import Button from "../Button.svelte";
    export let field;
    export let fieldValue;
    export let fieldIdx = "";
    export let errorValue;
    export let disabled = false;
    let fieldName = field.name + fieldIdx;
    let suggestions = [];
    let tempValue;

    const dispatch = createEventDispatcher();

	function handleInput(event) {
        const { value, checked } = event.target;

        if (field.options && value.length > 0) {
            suggestions = field.options.filter((option) =>
                option.toLowerCase().includes(value.toLowerCase())
            ).slice(0,5);
        } else {
            suggestions = [];
        }
        
        tempValue = field.inputType === "checkbox" ? checked : value;
        if (!field.multiple) {
		    dispatch('update', tempValue);
        }
	}

    function handleKeyDown(event) {
        if (event.key === 'Enter' && field.multiple && field.allowOwnOptions) {
            event.preventDefault();
            fieldValue.push(tempValue);
            dispatch('update', fieldValue);
        }
    }

    function handleSuggestion(value) {
        if (field.multiple) {
            fieldValue.push(value);
        } else {
            fieldValue = value;
        }
        dispatch('update', fieldValue);
        suggestions = [];
    }

    function removeOption(idx) {
        fieldValue.splice(idx, 1);
        dispatch('update', fieldValue);
    }

    function toggleDropdown() {
        if (suggestions.length === 0) {
            suggestions = field.options;
        } else {
            suggestions = [];
        }
    }
</script>

<div class={field.className}>
    <label class="block text-charcoal-gray text-sm font-bold mb-2 mt-auto" for={fieldName}>{field.label}</label>
    {#if field.inputType === "checkbox"}
        <input id={fieldName} name={fieldName} type="checkbox" checked={fieldValue}
            on:input={handleInput} disabled={disabled} autocomplete="off"/>
    {:else}
        <div class="relative w-full">
            <input id={fieldName} name={fieldName} type={field.inputType} value={field.multiple ? tempValue : fieldValue}
                on:input={handleInput} on:keydown={handleKeyDown} disabled={disabled} autocomplete="off" class="mt-1 block w-full"/>
            {#if field.options}
                <button type="button" class="absolute inset-y-0 right-2 flex items-center" on:click={toggleDropdown}>▼</button>
            {/if}
            <!-- Autocomplete -->
            {#if field.options && !disabled}
                <ul class="absolute w-full z-10 mt-2 bg-white max-h-60 overflow-y-auto">
                {#each suggestions as suggestion}
                    <li class="flex justify-between items-center cursor-pointer border border-gray-400">
                        <Button onclick={() => handleSuggestion(suggestion)} text={suggestion} 
                            class="w-full text-left px-4 py-2 hover:bg-gray-100"/>
                    </li>
                {/each}
                </ul>
            {/if}
        </div>
    {/if}
    <!-- Mostrar al usuario todas las opciones seleccionadas -->
    {#if field.multiple}
        <ul class="mt-3 max-h-30 overflow-y-auto">
        {#each fieldValue as value, idx}
            <li class="flex justify-between items-center px-4 py-2 border border-gray-300 rounded">
                {value}
                {#if !disabled}
                <Button onclick={() => removeOption(idx)} text="-"
                    class="px-4 py-2 border border-black rounded bg-red-700 text-white transition hover:bg-red-900"/>
                {/if}
            </li>
        {/each}
        </ul>
    {/if}
    <p class="text-red-500">{errorValue}</p>
</div>