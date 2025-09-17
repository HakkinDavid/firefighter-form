<!-- Modal básico de opciones -->
<script>
	import { drop_db, drop_settings } from "$lib/db/sqliteConfig";
	import { adminDialog } from "$lib/stores/adminDialogStore.svelte";
	import { dialog } from "$lib/stores/dialogStore.svelte";
	import { Preferences } from "@capacitor/preferences";
	import Modal from "../Modal.svelte";
	import { Capacitor } from "@capacitor/core";
	import { appFunctions } from "$lib/stores/appStore.svelte";

    let {
        active = $bindable(false),
    } = $props();

    function changeAdmin(){
        adminDialog.onAuthorize = async () => {
            if (Capacitor.getPlatform() === "web") {
                await Preferences.clear();
            } else {
                await drop_settings();
            }
            appFunctions.softReset();
        };
        adminDialog.onReject = () => {active = true};
        active = false;
        adminDialog.open();
    }

    function resetApplication(){
        const resetAndExit = async () => {
            await drop_db();
            await Preferences.clear();
            appFunctions.softReset();
        };
        active = false;
        dialog.open({
            title: "¿Está seguro que desea resetear la aplicación?⚠️",
            message: "Esta acción eliminará de forma permanente todos los datos guardados incluyendo registros y credenciales.",
			Accept: resetAndExit,
            AcceptLabel: "Estoy seguro",
            Cancel: () => {active = true},
        });
    }
</script>

<Modal bind:active>
    {#snippet header()}
        Opciones
    {/snippet}
    {#snippet body()}
        <div class="space-y-2 text-white text-base">
            <button class="w-full px-4 py-2 bg-wine rounded hover:bg-lightwine active:bg-lightwine hover:cursor-pointer"
                onclick={changeAdmin}>Cambiar supervisor
            </button>
            <button class="w-full px-4 py-2 bg-wine rounded hover:bg-lightwine active:bg-lightwine hover:cursor-pointer"
                onclick={resetApplication}>Resetear app
            </button>
        </div>
    {/snippet}
</Modal>