<script>
	import Header from "./Header.svelte";

	let {
        username = null,
        admin_username = ""
    } = $props();
</script>

<div class="w-full h-[9px] bg-wine"></div>
<Header bind:username bind:admin_username/>
<nav class="w-full bg-white border-b border-gray-300 px-4 py-3">
</nav>