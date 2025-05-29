<script>
    import { NOTICE_TYPES } from "$lib/Dictionary.svelte";
    let {
        status = $bindable(""),
        type = $bindable(NOTICE_TYPES.INFORMATION)
    } = $props();

    let style = $derived((() => {
        switch (type) {
            case NOTICE_TYPES.INFORMATION:
                return "bg-cyan-200 border-cyan-500"
            case NOTICE_TYPES.ERROR:
                return "bg-[rgba(240,0,0,0.5)] border-wine"
            case NOTICE_TYPES.WARNING:
                return "bg-yellow-200 border-yellow-500"
            case NOTICE_TYPES.SUCCESS:
                return "bg-green-200 border-green-500"
        }
    })())
</script>

<span class="flex flex-grow p-2 border-2 {style}">{status}</span>