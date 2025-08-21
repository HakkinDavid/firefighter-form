<script>
	import FormInput from "$lib/components/forms/FormInput.svelte";
	import FormSelect from "$lib/components/forms/FormSelect.svelte";
	import FormTextarea from "$lib/components/forms/FormTextarea.svelte";
	import FormMultipleOption from "./FormMultipleOption.svelte";
	import FormText from "./FormText.svelte";
    import FormDrawingBoard from "./FormDrawingBoard.svelte";
	import FormTuple from "./FormTuple.svelte";
	import { createEventDispatcher } from "svelte";
	import { FORM_STATUSES } from "$lib/Dictionary.svelte";
    import { handleFieldRestrictions, verifyRestrictions } from "./RestrictionHandler";
	import { derived } from "svelte/store";
	import SectionSelector from "./SectionSelector.svelte";
	import { fetchOptions } from "./FormOptions";
	import { get_db } from "$lib/db/sqliteConfig";
	import { debounce } from "$lib/debounce";
	import ModalDialog from "../ModalDialog.svelte";

    let localFormData = $state();
    let restrictions = $state({});
    let { template, formData, isPreviewOnly = false } = $props();

    let showConfirmation = $state(false);

    let section = $state("");
    // Obtener todos los campos del objeto en un arreglo aplanado
    const allFields = Object.values(template.fields).flat();
    const fieldsToDisplay = $derived(template.fields[section] ?? allFields);

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
        const data = {data: Object.fromEntries(allFields
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
        localFormData = {
            ...formData,
            data: {
                ...formData.data,
                filler: formData.filler,
                patient: formData.patient,
                date: formData.date
            }
        };
    }

    const fieldComponentMap = {
        input: FormInput,
        select: FormSelect,
        textarea: FormTextarea,
        multiple: FormMultipleOption,
        drawingboard: FormDrawingBoard, 
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
            return;
        }
        restrictions = handleFieldRestrictions(localFormData.data, template.restrictions);
        if (Object.keys(restrictions).length === 0 && showConfirmation == true ) { 
            localFormData.filler = localFormData.data.filler;
            delete localFormData.data.filler;

            localFormData.patient = localFormData.data.patient;
            delete localFormData.data.patient;

            localFormData.date = localFormData.data.date;
            delete localFormData.data.date;
            localFormData.status = completed ? FORM_STATUSES.FINISHED : FORM_STATUSES.DRAFT;
            dispatch('submit', localFormData);
            showConfirmation = false; // Quitamos confirmacion
        } else if (Object.keys(restrictions).length === 0 && showConfirmation == false) { // Si se cumple con las restricciones aun no esta el dialogo de confirmacion
            showConfirmation = true; // Se muestra el dialogo de confirmacion
        }
    }
    function shouldDisplay(field) {
        if (!field.display_on) return true;
        return verifyRestrictions(localFormData.data, field.display_on);
    }
    // Útil para arreglos y objetos con distintas referencias a memoria.
    function deepEqual(a, b) {
        return JSON.stringify(a) === JSON.stringify(b);
    }
    // Revisar esta implementación
    $effect(() => {
        let changed = false;
        for (const field of allFields) {
            const fieldName = field.name;
            const value = localFormData.data[fieldName];
            const visible = shouldDisplay(field);
            const opts = options[fieldName];

            if (!visible) {
                const newValue = fieldDataMap(field);
                if (!deepEqual(value, newValue)) {
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
                if (!deepEqual(filtered, value)) {
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

    // Para el caso de $derived.by asíncrono, el resultado es una promesa, no el resultado
    // de obtener las opciones, no activa reactividad.
    const derivedOptions = $derived.by(async () => {
        const result = {};
        const db = get_db();

        const setOption = async (name, requires, opts, fallback = null) => {
            if (!requires) {
                opts[name] = await fetchOptions(db, fallback);
                return;
            }
            for (const criterion of requires) {
                if (verifyRestrictions(localFormData.data, criterion)) {
                    opts[name] = await fetchOptions(db, criterion.filter);
                    return;
                }
            }
            opts[name] = await fetchOptions(db, fallback);
        };

        for (const field of allFields) {
            if (field.type === 'tuple') {
                result[field.name] = {};
                for (const subfield of field.tuple ?? []) {
                    if (subfield.options) {
                        await setOption(subfield.name, subfield.requires, result[field.name], subfield.options);
                    }
                }
            } else if (field.options) {
                await setOption(field.name, field.requires, result, field.options);
            }
        }
        return result;
    });
    // Opciones es un estado que almacena el resultado de la promesa derivedOptions
    let options = $state({});

    // El debounce evita muchas llamadas al derived.by asíncrono
    // Función auxiliar para aplicar el debounce y resolver la promesa
    const fetchDebouncedOptions = debounce(async () => {
        const newOptions = await derivedOptions;
        Object.assign(options, newOptions);
    }, 500);

    $effect(() => {
        // Importante para activar la reactividad
        const key = JSON.stringify(localFormData.data);
        fetchDebouncedOptions();
    });

    export { formData, localFormData, template };
</script>

<SectionSelector sections={Object.keys(template.fields)} bind:selected={section}/>
<div class="p-4">
    <h2><b>{template.formname}</b></h2>
    <form class="grid gap-4 grid-cols-[repeat(auto-fit,_minmax(200px,_1fr))]" id="template" onsubmit={(e) => {e.preventDefault(); console.log(localFormData)}}>
        {#each fieldsToDisplay as field (field.name)}
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

<div class="h-16"></div>
<div class="fixed bottom-0 left-0 w-full bg-gray-100 z-70 pb-4 pr-4 flex justify-end" hidden={isPreviewOnly}>
    <button type="button" form="template" onclick={() => handleSubmit(false)}
        class="mt-4 block cursor-pointer rounded bg-bronze px-4 py-2 text-white transition hover:bg-wine active:bg-wine mr-3">
        Guardar
    </button>
    <button type="button" form="template" onclick={() => handleSubmit(true)} 
        class="mt-4 block cursor-pointer rounded bg-wine px-4 py-2 text-white transition hover:bg-lightwine active:bg-lightwine">
        Finalizar
    </button>
</div>

<!-- Mensaje de confirmacion -->
<ModalDialog 
    message="¿Desea finalizar? Ya no podrá realizar cambios."
    Accept={() => handleSubmit(true)}
    AcceptLabel="Finalizar"
    bind:showDialog={showConfirmation}
/>