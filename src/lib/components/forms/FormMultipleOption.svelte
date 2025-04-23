<script>
    import { createEventDispatcher } from "svelte";
    export let field;
    export let fieldValue;
	export let fieldIdx = "";
    export let errorValue;
    export let disabled = false;
	let fieldName = field.name + fieldIdx;

    const dispatch = createEventDispatcher();

	function handleInput(event, option) {
		if (field.inputType === "checkbox") {
			let newValue;
			if (event.target.checked) {
				newValue = [...fieldValue, option];
			} else {
				newValue = fieldValue.filter(item => item !== option);
			}
			dispatch("update", newValue);
		} else {
			dispatch("update", option);
		}
	}

    function isChecked(option) {
		if (field.inputType === "checkbox") {
			return fieldValue.includes(option);
		}
		return fieldValue === option;
	}
</script>

<div class={field.className}>
    <p class="block text-gray-700 text-sm font-bold mb-2">{field.label}</p>

    {#each field.options as option}
		<label class="flex items-center space-x-2 mb-1">
            <!-- Input type debe ser checkbox o radio -->
			<input type={field.inputType} name={fieldName} value={option}
				checked={isChecked(option)}
				on:change={(e) => handleInput(e, option)}
				disabled={disabled}
			/>
			<span>{option}</span>
		</label>
	{/each}
    <p class="text-red-500">{errorValue}</p>
</div>