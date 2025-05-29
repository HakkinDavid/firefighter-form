<script>
	import Modal from "$lib/components/Modal.svelte";
    import { ACTION_STATUSES, NOTICE_TYPES } from "$lib/Dictionary.svelte";
	import Notice from "$lib/components/Notice.svelte";
    import { createEventDispatcher, onMount } from "svelte";
    import bcrypt from "bcryptjs";

    let admin_username = $state('');
    let admin_password = $state('');
    let password_confirmation = $state('');
    let notice_type = $state(NOTICE_TYPES.WARNING);
    let status = $state(ACTION_STATUSES.UNAUTHORIZED);

    let is_input_valid = $derived.by(
        () => {
            return admin_username.length >= 4 && admin_password.length >= 8 && admin_password === password_confirmation;
        }
    );
    
    const dispatch = createEventDispatcher();

    let {
        active = $bindable(false),
        settings = $bindable()
    } = $props();

    async function authorize () {
          if (!admin_username || !admin_password) {
            notice_type = NOTICE_TYPES.ERROR;
            status = ACTION_STATUSES.REQUIRED;
          }
          else if (settings.admin_username === admin_username && (await bcrypt.compare(admin_password, settings.admin_password))) {
            notice_type = NOTICE_TYPES.SUCESS;
            status = ACTION_STATUSES.AUTHORIZED;
            dispatch('authorized');
            close(true);
            console.log("Autorización concedida.");
          }
          else {
            notice_type = NOTICE_TYPES.ERROR;
            status = ACTION_STATUSES.BAD_CREDENTIALS;
          }
    }

    async function register () {
        if (!admin_username || !admin_password) {
            notice_type = NOTICE_TYPES.ERROR;
            status = ACTION_STATUSES.REQUIRED;
            return;
        }
        else if (admin_password !== password_confirmation) {
            notice_type = NOTICE_TYPES.ERROR;
            status = ACTION_STATUSES.MISMATCH;
            return;
        }
        else if (!is_input_valid) {
            notice_type = NOTICE_TYPES.ERROR;
            status = ACTION_STATUSES.WRONG_FORMAT;
            return;
        }

        settings.admin_username = admin_username;
        settings.admin_password = await bcrypt.hash(admin_password, 10);
        dispatch('registered');
        close(true);
        console.log("Supervisor registrado.");
    }

    export function open (n_type, a_status) {
        if (!isNaN(n_type)) notice_type = n_type;
        if (a_status) status = a_status;
        active = true;
        dispatch('open');
    }

    export function close (successfully = false) {
        active = false;
        if (successfully !== true) {
            console.log("Autorización negada.");
            dispatch('cancel');
        }
        dispatch('close');
        reset();
    }

    function reset () {
        admin_username = '';
        admin_password = '';
        password_confirmation = '';
        notice_type = NOTICE_TYPES.WARNING;
        status = ACTION_STATUSES.UNAUTHORIZED;
    }

    let settings_is_undefined = $derived(!settings);
    let first_time_setup = $derived(settings && (!settings.admin_username || !settings.admin_password));
</script>

{#if settings_is_undefined}
    <Modal bind:active on:close={close}>
        {#snippet header()}
            Acción supervisada
        {/snippet}
        {#snippet body()}
            <Notice status={ACTION_STATUSES.CANNOT_AUTH} type={NOTICE_TYPES.ERROR} />
        {/snippet}
    </Modal>
{:else}
    <Modal bind:active on:close={close} close_button={!first_time_setup}>
        {#snippet header()}
            Acción supervisada
        {/snippet}
        {#snippet body()}
            <Notice bind:status bind:type={notice_type}/>
            <input type="text" required placeholder="Nombre de acceso" class="w-full text-charcoal-gray text-sm font-bold mt-2" bind:value={admin_username}/>
            <input type="password" required placeholder="Contraseña de acceso" class="w-full text-charcoal-gray text-sm font-bold mt-2" bind:value={admin_password}/>
            {#if first_time_setup}
                <input type="password" required placeholder="Repita la contraseña de acceso" class="w-full text-charcoal-gray text-sm font-bold mt-2" bind:value={password_confirmation}/>
            {/if}
        {/snippet}
        {#snippet children()}
            {#if first_time_setup}
                <button
                    class="bg-green-500 w-full text-white px-4 py-2 rounded hover:bg-green-400 cursor-pointer"
                    onclick={register}
                >
                    Registrar
                </button>
                <button
                    class="bg-red-500 w-full text-white px-4 py-2 rounded hover:bg-red-400 cursor-pointer"
                    onclick={close}
                >
                    Salir del app
                </button>
            {:else}
                <button
                    class="bg-wine w-full text-white px-4 py-2 rounded hover:bg-lightwine cursor-pointer"
                    onclick={authorize}
                >
                    Autorizar
                </button>
            {/if}
        {/snippet}
    </Modal>
{/if}