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
	import FormError from "./FormError.svelte";
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
    <p class="block text-charcoal-gray text-sm font-bold mb-2 col-span-full sticky top-0 bg-white z-50 h-min">{field.label}</p>
    {#each fieldValue as tuple, idx}
        {#each field.tuple as subfield}
            {#if fieldComponentMap[subfield.type]}
                <svelte:component this={fieldComponentMap[subfield.type]} field={subfield} disabled={disabled}
                fieldValue={tuple[subfield.name]} fieldIdx={idx}
                errorValue={errorValue?.[idx]?.[subfield.name] || ''}
                on:update={(e) => updateField(idx, subfield.name, e.detail)}/>
            {/if}
        {/each}
        {#if !disabled}
        <div class="col-span-1 flex items-end">
            <Button onclick={() => removeTuple(idx)} text="Eliminar"
                class="w-full py-2 rounded-lg cursor-pointer border border-black bg-red-700 text-white transition hover:bg-red-900"/>
        </div>
        {/if}
    {/each}
    {#if !disabled}
    <div class="col-span-full sticky bottom-0 bg-white h-min">
        <Button onclick={addTuple} text="Añadir" 
        class="w-min px-6 py-2 rounded-lg cursor-pointer border border-black bg-bronze text-white transition hover:bg-wine"/>
    </div>
    {/if}
    <!-- <FormError errorValue/> -->
</div>