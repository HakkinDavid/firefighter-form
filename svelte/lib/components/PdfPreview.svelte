<script>
	import FormRenderer from "./forms/FormRenderer.svelte";

    let { formData, template } = $props();
</script>

<div>
    <FormRenderer formData={formData} template={template} isPreviewOnly />
</div>