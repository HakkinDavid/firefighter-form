<script>
	import FormInput from "$lib/components/forms/FormInput.svelte";
	import FormSelect from "$lib/components/forms/FormSelect.svelte";
	import FormTextarea from "$lib/components/forms/FormTextarea.svelte";
	import FormMultipleOption from "./FormMultipleOption.svelte";
	import FormText from "./FormText.svelte";
    import FormSignature from "./FormSignature.svelte";
	import FormTuple from "./FormTuple.svelte";
	import { createEventDispatcher } from "svelte";
	import { STATUSES } from "$lib/Dictionary.svelte";
    import { handleFieldRestrictions } from "./RestrictionHandler";

    let localFormData = $state();
    let restrictions = $state({});
    let { template, formData, isPreviewOnly = false } = $props();

    const dispatch = createEventDispatcher();

    function defaultFormData(template) {
        const data = {data: Object.fromEntries(template.fields
            .filter(field => field.type !== 'text')
            .map(field => {
            let defaultValue;
            if (field.multiple || field.type === 'tuple' || (field.type === 'multiple' && field.inputType === 'checkbox')) {
                defaultValue = [];
            } else if (field.inputType === 'checkbox') {
                defaultValue = false;
            } else {
                defaultValue = "";
            }
            return [field.name, defaultValue];
        }))};
        data.status = STATUSES.NEW;
        return data;
    }

    if (formData === undefined) {
        localFormData = defaultFormData(template);
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
            localFormData.status = completed ? STATUSES.FINISHED : STATUSES.DRAFT;
            dispatch('submit', localFormData);
            localFormData.filler = localFormData.data.filler;
            localFormData.patient = localFormData.data.patient;
            localFormData.date = localFormData.data.date;
        }
        restrictions = handleFieldRestrictions(localFormData.data, template.restrictions);
        if (Object.keys(restrictions).length === 0 ) {
            localFormData.filler = localFormData.data.filler;
            delete localFormData.data.filler;

            localFormData.patient = localFormData.data.patient;
            delete localFormData.data.patient;

            localFormData.date = localFormData.data.date;
            delete localFormData.data.date;
            localFormData.status = completed ? STATUSES.FINISHED : STATUSES.DRAFT;
            dispatch('submit', localFormData);
        }
    }

    export { formData, localFormData };
</script>

<div class="p-4">
    <h2><b>{template.formname}</b></h2>
    <form class="grid gap-4 grid-cols-[repeat(auto-fit,_minmax(200px,_1fr))]" id="template" onsubmit={(e) => {e.preventDefault(); console.log(localFormData)}}>
        {#each template.fields as field (field.name)}
            {#if fieldComponentMap[field.type]}
                {@const Component = fieldComponentMap[field.type]}
                <Component {field}
                fieldValue={localFormData.data[field.name]}
                errorValue={restrictions[field.name]}
                disabled={isPreviewOnly}
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