<script>
    import Logo from "$lib/components/Logo.svelte";
	import Button from "./Button.svelte";
    import { createEventDispatcher } from "svelte";
    const dispatch = createEventDispatcher();
</script>

<div class="flex w-full h-full flex-col place-content-center justify-center px-4 py-8 text-center gap-8">
    <div class="flex flex-row place-content-center justify-center gap-12">
        <Logo type={"Tijuana"} />
        <div class="flex flex-col text-lg">
            <p>AYUNTAMIENTO DE TIJUANA, B.C.</p>
            <p>DIRECCIÓN DE BOMBEROS TIJUANA</p>
            <p>PARTE DE SERVICIO PREHOSPITALARIO</p>
        </div>
        <Logo type={"Bomberos"} />
    </div>
    <div class="flex mt-16 justify-center">
        <Button text="Entrar" onclick={() => {
            dispatch('login');
        }} />
    </div>
</div>