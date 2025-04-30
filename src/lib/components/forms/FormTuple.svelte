<!-- Una tupla encapsula mini-formularios que pueden llenarse varias veces -->
<script>
    import { createEventDispatcher } from "svelte";
    import FormInput from "$lib/components/forms/FormInput.svelte";
	import FormSelect from "$lib/components/forms/FormSelect.svelte";
	import FormTextarea from "$lib/components/forms/FormTextarea.svelte";
	import FormMultipleOption from "./FormMultipleOption.svelte";
	import FormText from "./FormText.svelte";
	import FormTuple from "./FormTuple.svelte";
	import Button from "../Button.svelte";
    export let field;
    export let fieldValue = [];
    export let errorValue;
    export let disabled = false;

    const dispatch = createEventDispatcher();

    function addTuple(){
        let formData = Object.fromEntries(field.tuple
                .filter(field => field.type !== 'text')
                .map(field => {
            let defaultValue;
            if (field.multiple || (field.type === 'multiple' && field.inputType === 'checkbox')) {
                defaultValue = [];
            } else if (field.inputType === 'checkbox') {
                defaultValue = false;
            } else {
                defaultValue = "";
            }
            return [field.name, defaultValue];
        }));
        fieldValue.push(formData);
        dispatch('update', fieldValue);
    }

    function removeTuple(index) {
        fieldValue = fieldValue.filter((_, i) => i !== index);
        dispatch('update', fieldValue);
    }

	function updateField(idx, name, value) {
        fieldValue[idx][name] = value;
        fieldValue = [...fieldValue];
        dispatch('update', fieldValue);
    }

    const fieldComponentMap = {
        input: FormInput,
        select: FormSelect,
        textarea: FormTextarea,
        multiple: FormMultipleOption,
        text: FormText
    };
</script>

<div class={field.className}>
    <p class="block text-gray-700 text-sm font-bold mb-2">{field.label}</p>
    {#each fieldValue as tuple, idx}
        {#each field.tuple as subfield}
            {#if fieldComponentMap[subfield.type]}
                <svelte:component this={fieldComponentMap[subfield.type]} field={subfield} disabled={disabled}
                fieldValue={tuple[subfield.name]} fieldIdx={idx}
                on:update={(e) => updateField(idx, subfield.name, e.detail)}/>
            {/if}
        {/each}
        <Button 
        class="mt-4 block cursor-pointer rounded bg-red-500 px-4 py-2 text-white transition hover:bg-red-600 mx-8"
        onclick={() => removeTuple(idx)} text="Eliminar"/>
    {/each}
    {#if !disabled}
    <div>
        <Button 
        class="mt-4 block cursor-pointer rounded bg-blue-500 px-4 py-2 text-white transition hover:bg-blue-600 mx-8"
        onclick={addTuple} text="Añadir"/>
    </div>
    {/if}
    <p class="text-red-500">{errorValue}</p>
</div>