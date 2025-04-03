<!-- +page.svelte -->
<script>
    import WelcomeScreen from '$lib/components/WelcomeScreen.svelte';
    import FormsList from '$lib/components/FormsList.svelte';
    import Button from '$lib/components/Button.svelte';
    
    import { Preferences } from '@capacitor/preferences';
    import { onMount } from 'svelte';

    let forms = $state(undefined);
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

    // Se ejecuta al montar el componente, recuperando los formularios guardados
    onMount(async () => {
        forms = await get_object('forms');
        if (!forms) forms = [];
    });
</script>

{#if !logged_in}
    <!-- Pantalla de bienvenida que se muestra antes de iniciar sesión -->
    <WelcomeScreen on:login={() => {
        logged_in = true;
    }}/>
{:else}
    <!-- Lista de formularios cargados -->
    <FormsList bind:forms={forms}/>
    <div class="flex w-full justify-center place-items-center">
        <!-- Botón para añadir un formulario de prueba -->
        <Button onclick={() => { forms.push({
            date: new Date(),
            filler: {
                name: "Bombero Prueba"
            },
            patient: {
                name: "Paciente Prueba"
            },
            status: "Completo"
        }) }} 
        text="Añadir registro de prueba"
        class="w-min px-6 py-2 rounded-lg cursor-pointer border border-black bg-red-500 text-white"/>
    </div>
{/if}