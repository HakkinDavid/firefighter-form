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
	import { verifyRestrictions } from "./RestrictionHandler";
    let { field, fieldValue = [], errorValue, disabled = false, localFormData, options } = $props();

    const dispatch = createEventDispatcher();

    const fieldDataMap = (field) => {
        let defaultValue;
        if (field.multiple || (field.type === 'multiple' && field.inputType === 'checkbox')) {
            defaultValue = [];
        } else if (field.inputType === 'checkbox') {
            defaultValue = false;
        } else {
            defaultValue = "";
        }
        return defaultValue;
    }

    function addTuple(){
        let formData = Object.fromEntries(field.tuple
                .filter(field => field.type !== 'text')
                .map(field => {
            return [field.name, fieldDataMap(field)];
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

    function shouldDisplay(field, idx) {
        if (!field.display_on) return true;
        return verifyRestrictions(localFormData.data, field.display_on, idx);
    }
    // Revisar esta implementación
    $effect(() => {
        let changed = false;
        for (const [idx, tuple] of fieldValue.entries()) {
            for (const subfield of field.tuple) {
                const fieldName = subfield.name;
                const value = fieldValue[idx][fieldName];
                const visible = shouldDisplay(subfield, idx);
                const opts = options?.[fieldName];

                if (!visible) {
                    const newValue = fieldDataMap(subfield);
                    if (value !== newValue) {
                        fieldValue[idx][fieldName] = newValue;
                        changed = true;
                    }
                    continue;
                }

                if (!opts) continue;
                // Inputs normales no se eliminan los datos
                if ((subfield.type === 'input' && !subfield.multiple) || subfield.allowOwnOptions) 
                    continue;
                // Campos con múltiple selección se borran los datos no válidos
                else if (subfield.multiple || (subfield.type === 'multiple' && subfield.inputType === 'checkbox')) {
                    const filtered = value?.filter(v => opts.includes(v)) ?? [];
                    if (JSON.stringify(filtered) !== JSON.stringify(value)) {
                        fieldValue[idx][fieldName] = filtered;
                        changed = true;
                    }
                } else {
                    if (!opts.includes(value)) {
                        const newValue = fieldDataMap(subfield);
                        if (value !== newValue) {
                            fieldValue[idx][fieldName] = newValue;
                            changed = true;
                        }
                    }
                }         
            }
        }
    });
</script>

<div class={field.className}>
    <p class="block text-charcoal-gray text-sm font-bold mb-2 col-span-full top-0 bg-white h-min">{field.label}</p>
    {#each fieldValue as tuple, idx}
        {#each field.tuple as subfield}
            {#if fieldComponentMap[subfield.type] && shouldDisplay(subfield, idx)}
            {@const Component = fieldComponentMap[subfield.type]}
                <Component field={subfield} disabled={disabled}
                fieldValue={tuple[subfield.name]} fieldIdx={idx}
                errorValue={errorValue?.[idx]?.[subfield.name] || ''}
                options={options?.[subfield.name]}
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
    <!-- <FormError bind:errorValue/> -->
</div>