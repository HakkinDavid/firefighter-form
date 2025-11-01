<!-- WelcomeScreen.svelte -->
<script>
    import Icon from "$lib/components/Icon.svelte";
    import Button from "./Button.svelte";
    import { createEventDispatcher } from "svelte";
    const dispatch = createEventDispatcher();
</script>

<!-- Pantalla de bienvenida con logotipos y botón de inicio -->
<div class="flex w-full h-full flex-col place-content-center justify-center px-4 py-8 text-center gap-8">
   
    <div class="flex mt-16 justify-center">
        <!-- Botón para iniciar sesión -->
        <Button 
        text="Entrar" onclick={() => {
            dispatch('login');
        }} 
        class="w-min cursor-pointer rounded-lg border border-black bg-wine text-white transition hover:bg-lightwine active:bg-lightwine px-6 py-2"

        />
    </div>
</div>