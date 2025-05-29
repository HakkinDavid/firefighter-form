<script>
	import FormInput from "$lib/components/forms/FormInput.svelte";
	import FormSelect from "$lib/components/forms/FormSelect.svelte";
	import FormTextarea from "$lib/components/forms/FormTextarea.svelte";
	import FormMultipleOption from "./FormMultipleOption.svelte";
	import FormText from "./FormText.svelte";
    import FormSignature from "./FormSignature.svelte";
	import FormTuple from "./FormTuple.svelte";
	import { createEventDispatcher } from "svelte";
	import { FORM_STATUSES } from "$lib/Dictionary.svelte";
    import { handleFieldRestrictions, verifyRestrictions } from "./RestrictionHandler";
	import { derived } from "svelte/store";

    let localFormData = $state();
    let restrictions = $state({});
    let { template, formData, isPreviewOnly = false } = $props();

    const dispatch = createEventDispatcher();

    const fieldDataMap = (field) => {
        let defaultValue;
        if (field.multiple || field.type === 'tuple' || (field.type === 'multiple' && field.inputType === 'checkbox')) {
            defaultValue = [];
        } else if (field.inputType === 'checkbox') {
            defaultValue = false;
        } else {
            defaultValue = "";
        }
        return defaultValue;
    }

    function defaultFormData(template) {
        const data = {data: Object.fromEntries(template.fields
            .filter(field => field.type !== 'text')
            .map(field => {
            return [field.name, fieldDataMap(field)];
        }))};
        data.status = FORM_STATUSES.NEW;
        return data;
    }

    if (formData === undefined) {
        localFormData = defaultFormData(template);
        if (!isNaN(localFormData.id)) console.log("Se eliminará este extraño ID (" + localFormData.id + "), investigaremos de dónde sale.");
        delete localFormData.id;
    } else {
        localFormData = { ...formData };
        localFormData.data.filler = formData.filler;
        localFormData.data.patient = formData.patient;
        localFormData.data.date = formData.date;
    }

    const fieldComponentMap = {
        input: FormInput,
        select: FormSelect,
        textarea: FormTextarea,
        multiple: FormMultipleOption,
        signature: FormSignature,    
        tuple: FormTuple,
        text: FormText
    };

    function handleSubmit(completed) {
        if (!completed){
            localFormData.status = completed ? FORM_STATUSES.FINISHED : FORM_STATUSES.DRAFT;
            localFormData.filler = localFormData.data.filler ?? "No especificado";
            localFormData.patient = localFormData.data.patient ?? "No especificado";
            localFormData.date = localFormData.data.date ?? (new Date()).toISOString().split("T")[0];
            dispatch('submit', localFormData);
        }
        restrictions = handleFieldRestrictions(localFormData.data, template.restrictions);
        if (Object.keys(restrictions).length === 0 ) {
            localFormData.filler = localFormData.data.filler;
            delete localFormData.data.filler;

            localFormData.patient = localFormData.data.patient;
            delete localFormData.data.patient;

            localFormData.date = localFormData.data.date;
            delete localFormData.data.date;
            localFormData.status = completed ? FORM_STATUSES.FINISHED : FORM_STATUSES.DRAFT;
            dispatch('submit', localFormData);
        }
    }
    function shouldDisplay(field) {
        if (!field.display_on) return true;
        return verifyRestrictions(localFormData.data, field.display_on);
    }
    // Revisar esta implementación
    $effect(() => {
        let changed = false;
        for (const field of template.fields) {
            const fieldName = field.name;
            const value = localFormData.data[fieldName];
            const visible = shouldDisplay(field);
            const opts = options[fieldName];

            if (!visible) {
                const newValue = fieldDataMap(field);
                if (value !== newValue) {
                    localFormData.data[fieldName] = newValue;
                    changed = true;
                }
                continue;
            }

            if (!opts) continue;
            // Inputs normales no se eliminan los datos, tuplas son manejadas distinto
            if ((field.type === 'input' && !field.multiple) || field.type === 'tuple' || field.allowOwnOptions) 
                continue;
            // Campos con múltiple selección se borran los datos no válidos
            else if (field.multiple || (field.type === 'multiple' && field.inputType === 'checkbox')) {
                const filtered = value?.filter(v => opts.includes(v)) ?? [];
                if (JSON.stringify(filtered) !== JSON.stringify(value)) {
                    localFormData.data[fieldName] = filtered;
                    changed = true;
                }
            } else {
                if (!opts.includes(value)) {
                    const newValue = fieldDataMap(field);
                    if (value !== newValue) {
                        localFormData.data[fieldName] = newValue;
                        changed = true;
                    }
                }
            }         
        }
    });

    // Derivar las opciones directamente de localFormData
    const options = $derived.by(() => {
        const result = {};

        const setOption = (name, requires, opts, fallback = null) => {
            if (!requires) {
                opts[name] = fallback ?? null;
                return;
            }
            for (const criterion of requires) {
                if (verifyRestrictions(localFormData.data, criterion)) {
                    opts[name] = criterion.filter;
                    return;
                }
            }
            opts[name] = fallback ?? null;
        };

        for (const field of template.fields) {
            if (field.type === 'tuple') {
                result[field.name] = {};
                for (const subfield of field.tuple ?? []) {
                    if (subfield.options) {
                        setOption(subfield.name, subfield.requires, result[field.name], subfield.options);
                    }
                }
            } else if (field.options) {
                setOption(field.name, field.requires, result, field.options);
            }
        }
        return result;
    });

    export { formData, localFormData };
</script>

<div class="p-4">
    <h2><b>{template.formname}</b></h2>
    <form class="grid gap-4 grid-cols-[repeat(auto-fit,_minmax(200px,_1fr))]" id="template" onsubmit={(e) => {e.preventDefault(); console.log(localFormData)}}>
        {#each template.fields as field (field.name)}
            {#if fieldComponentMap[field.type] && shouldDisplay(field)}
                {@const Component = fieldComponentMap[field.type]}
                <Component {field}
                fieldValue={localFormData.data[field.name]}
                errorValue={restrictions[field.name]}
                disabled={isPreviewOnly}
                options={options[field.name]}
                localFormData={field.type === "tuple" ? localFormData : null}
                on:update={(e) => localFormData.data[field.name] = e.detail}/>
            {/if}
        {/each}
    </form>
</div>

<div class="flex justify-end sticky bottom-0 bg-gray-100 z-70 pb-4 pr-4" hidden={isPreviewOnly}>
    <button type="button" form="template" onclick={() => handleSubmit(false)}
        class="mt-4 block cursor-pointer rounded bg-bronze px-4 py-2 text-white transition hover:bg-wine mr-3">
        Guardar
    </button>
    <button type="button" form="template" onclick={() => handleSubmit(true)} 
        class="mt-4 block cursor-pointer rounded bg-wine px-4 py-2 text-white transition hover:bg-lightwine">
        Finalizar
    </button>
</div>