<!-- +page.svelte -->
 <!-- /form-->
<script>
    import Header from '$lib/components/Header.svelte';
    import FormsList from '$lib/components/FormsList.svelte';
    import Button from '$lib/components/Button.svelte';
    
    import { Preferences } from '@capacitor/preferences';
    import { onMount } from 'svelte';

    import FormRenderer from '$lib/components/forms/FormRenderer.svelte';
    import formulario from './campos.json';


    let forms = $state([]);
    let logged_in = $state(false);


    // Función para guardar un objeto en almacenamiento persistente
    async function set_object(k, v) {
        await Preferences.set({
            key: k,
            value: JSON.stringify(v)
        });
    }

    // Función para recuperar un objeto desde el almacenamiento
    async function get_object(k) {
        return JSON.parse((await Preferences.get({ key: k })).value);
    }
</script>
<Header></Header>

<div class="flex w-full justify-center place-items-center">
    <FormRenderer template={formulario}/>

</div>






