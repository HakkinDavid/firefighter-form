<script>
	import FormInput from "$lib/components/forms/FormInput.svelte";
	import FormSelect from "$lib/components/forms/FormSelect.svelte";
	import FormTextarea from "$lib/components/forms/FormTextarea.svelte";
	import FormMultipleOption from "./FormMultipleOption.svelte";
	import FormText from "./FormText.svelte";
    import FormSignature from "./FormSignature.svelte";
	import FormTuple from "./FormTuple.svelte";
	import { createEventDispatcher } from "svelte";

    export let template;
    export let formData;
    let localFormData;

    const dispatch = createEventDispatcher();

    function defaultFormData(template) {
        const data = Object.fromEntries(template.fields
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
        }));
        data.date = new Date();
        data.status = "Nuevo";
        return data;
    }

    if (formData === undefined) {
        localFormData = defaultFormData(template);
    } else {
        localFormData = { ...formData };
    }
    let ReadOnly = localFormData.status === "Completado";

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
        localFormData.status = completed ? "Completado" : "Guardado";
        dispatch('submit', localFormData);
    }
</script>

<div>
    <form class="" id="template" on:submit|preventDefault={() => console.log(localFormData)}>
        <h2><b>{template.formname}</b></h2>
        {#each template.fields as field (field.name)}
            {#if fieldComponentMap[field.type]}
                <svelte:component this={fieldComponentMap[field.type]} {field} disabled={ReadOnly}
                fieldValue={localFormData[field.name]} 
                on:update={(e) => localFormData[field.name] = e.detail}/>
            {/if}
        {/each}
        <div class="flex justify-end">
            {#if !ReadOnly}
            <button type="button" form="template" on:click={() => handleSubmit(false)}
                class="mt-4 block cursor-pointer rounded bg-gray-400 px-4 py-2 text-white transition hover:bg-gray-600 mr-3">
                Guardar
            </button>
            <button type="button" form="template" on:click={() => handleSubmit(true)} 
                class="mt-4 block cursor-pointer rounded bg-blue-500 px-4 py-2 text-white transition hover:bg-blue-600">
                Finalizar
            </button>
            {/if}
        </div>
    </form>
</div>