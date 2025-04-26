<script>
	import FormInput from "$lib/components/forms/FormInput.svelte";
	import FormSelect from "$lib/components/forms/FormSelect.svelte";
	import FormTextarea from "$lib/components/forms/FormTextarea.svelte";
	import FormMultipleOption from "./FormMultipleOption.svelte";
	import FormText from "./FormText.svelte";
    import FormSignature from "./FormSignature.svelte";
	import FormTuple from "./FormTuple.svelte";

    export let template;
    export let ReadOnly = false;
    let formData = Object.fromEntries(template.fields
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

    const fieldComponentMap = {
        input: FormInput,
        select: FormSelect,
        textarea: FormTextarea,
        multiple: FormMultipleOption,
        signature: FormSignature,    
        tuple: FormTuple,
        text: FormText
    };

</script>

<div>
    <form class="" id="template" on:submit|preventDefault={() => console.log(formData)}>
        <h2><b>{template.formname}</b></h2>
        {#each template.fields as field (field.name)}
            {#if fieldComponentMap[field.type]}
                <svelte:component this={fieldComponentMap[field.type]} {field} disabled={ReadOnly}
                fieldValue={formData[field.name]} 
                on:update={(e) => formData[field.name] = e.detail}/>
            {/if}
        {/each}
        <button type="submit" form="template">Guardar</button>
    </form>
</div>