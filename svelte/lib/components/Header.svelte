<!-- Header.svelte -->
<script>
    import Icon from "$lib/components/Icon.svelte";
	import SettingsModal from "./settings/SettingsModal.svelte";

    let {
        username = null,
        admin_username = ""
    } = $props();
    let activeSM = $state(false);
</script>

<!-- Header -->
<div class="bg-wine text-white flex w-full h-full flex-col place-content-center justify-center px-4 py-8 text-center gap-8">
    <div class="flex flex-row place-content-center justify-center gap-12">
        <Icon type="Tijuana" />
        <div class="flex flex-col text-lg">
            <p>AYUNTAMIENTO DE TIJUANA, B.C.</p>
            <p>DIRECCIÓN DE BOMBEROS TIJUANA</p>
            <p>PARTE DE SERVICIO PREHOSPITALARIO</p>

            {#if username}
                <p>Usuario: {username}</p>
            {/if}
            <div class="flex items-center justify-center gap-2">
                <p>Supervisor: {admin_username}</p>
                <button onclick={() => activeSM = true}>
                    <Icon type="Engranaje" class="h-6 w-6 hover:text-gray-400 active:text-gray-400"/>
                </button>
            </div>
        </div>
        <Icon type="Bomberos" />
    </div>
</div>

<SettingsModal bind:active={activeSM}/>