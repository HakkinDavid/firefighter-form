<script>
    import WelcomeScreen from '$lib/components/WelcomeScreen.svelte';
    import FormsList from '$lib/components/FormsList.svelte';

    import { Preferences } from '@capacitor/preferences';
	import { onMount } from 'svelte';

    let forms = $state(undefined);
    let logged_in = $state(false);

    async function set_object(k, v) {
        await Preferences.set({
            key: k,
            value: JSON.stringify(v)
        });
    }

    async function get_object(k) {
        return JSON.parse((await Preferences.get({ key: k })).value);
    }

    onMount(async () => {
        forms = await get_object('forms');
        if (!forms) forms = [];

    });
</script>

{#if !logged_in}
    <WelcomeScreen on:login={() => {
        logged_in = true;
    }}/>
{:else}
    <FormsList bind:forms={forms}/>
{/if}