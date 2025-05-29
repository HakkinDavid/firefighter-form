<script>
    let {
        active = $bindable(false),
        close_button = $bindable(true),
        header,
        body,
        footer,
        children
    } = $props();

    function toggle () {
        active = !active;
    }
</script>

<!-- Modal -->
{#if active}
    <!-- svelte-ignore a11y_click_events_have_key_events -->
    <!-- svelte-ignore a11y_no_static_element_interactions -->
    <div class="fixed inset-0 flex justify-center items-center z-[1000]" style="background-color: rgba(0,0,0,0.5)" onclick={toggle}>
        <div class="bg-white rounded-xl p-6 w-11/12 max-w-md shadow-lg" onclick={e => e.stopPropagation()}>
            {#if header}
                <h2 class="text-lg lg:text-xl font-bold mb-4">
                    {@render header()}
                </h2>
            {/if}
            {#if body}
                <p class="text-black text-sm lg:text-md text-justify space-y-">
                    {@render body()}
                </p>
            {/if}
            {#if footer}
                <div class="mt-4 text-xs lg:text-sm text-black leading-relaxed">
                    {@render footer()}
                </div>
            {/if}

            {#if close_button || children}
                <div class="mt-6 flex flex-col gap-2 flex-grow place-content-end">
                    {#if children}
                        {@render children()}
                    {/if}
                    <button
                        class="bg-sand w-full text-white px-4 py-2 rounded hover:bg-sand cursor-pointer"
                        onclick={toggle}
                        hidden={!close_button}
                    >
                        Cerrar
                    </button>
                </div>
            {/if}
        </div>
    </div>
{/if}