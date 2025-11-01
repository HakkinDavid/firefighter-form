<script>
	import RootPage from "$lib/components/RootPage.svelte";
	import { disconnect_db } from "$lib/db/sqliteConfig";
	import { appFunctions } from "$lib/stores/appStore.svelte";
	import { onMount } from "svelte";

	let pageKey = $state(0);
	onMount(() => {
		appFunctions.onReset = async () => {
			await disconnect_db();
			pageKey = !pageKey;
		}
	});
</script>

{#key pageKey}
	<RootPage/>
{/key}