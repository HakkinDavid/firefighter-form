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
    <label class="block text-gray-700 text-sm font-bold mb-2" for={fieldName}>{field.label}</label>
    {#if field.inputType === "checkbox"}
        <input id={fieldName} name={fieldName} type="checkbox" checked={fieldValue}
            on:input={handleInput} disabled={disabled} autocomplete="off"/>
    {:else}
        <input id={fieldName} name={fieldName} type={field.inputType} value={field.multiple ? tempValue : fieldValue}
            on:input={handleInput} on:keydown={handleKeyDown} disabled={disabled} autocomplete="off"/>
        {#if field.options}
            <button type="button" class="toggle" on:click={toggleDropdown}>▼</button>
        {/if}
    {/if}
    <!-- Autocomplete -->
    {#if field.options}
        <ul>
        {#each suggestions as suggestion}
            <li>
                {suggestion}
                <Button onclick={() => handleSuggestion(suggestion)} text="+"/>
            </li>
        {/each}
        </ul>
    {/if}
    <!-- Mostrar al usuario todas las opciones seleccionadas -->
    {#if field.multiple}
        <ul>
        {#each fieldValue as value, idx}
            <li>
                {value}
                <Button onclick={() => removeOption(idx)} text="-"/>
            </li>
        {/each}
        </ul>
    {/if}
    <p class="text-red-500">{errorValue}</p>
</div>