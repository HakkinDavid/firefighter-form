<!-- Modal básico de opciones -->
<script>
	import { drop_db, drop_settings } from "$lib/db/sqliteConfig";
	import { adminDialog } from "$lib/stores/adminDialogStore.svelte";
	import { dialog } from "$lib/stores/dialogStore.svelte";
	import { Preferences } from "@capacitor/preferences";
	import Modal from "../Modal.svelte";
	import { Capacitor } from "@capacitor/core";

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
            window.location.reload();
        };
        adminDialog.onReject = () => {active = true};
        active = false;
        adminDialog.open();
    }

    function resetApplication(){
        const resetAndExit = async () => {
            await drop_db();
            await Preferences.clear();
            window.location.reload();
        };
        active = false;
        dialog.open({
            message: "¿Está seguro que desea resetear la aplicación? Se borrarán todos los datos.",
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