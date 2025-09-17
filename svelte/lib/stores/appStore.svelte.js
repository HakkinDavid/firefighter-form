let resetFn = $state(() => {});

export const appFunctions = {
    set onReset(fn) {resetFn = fn},
    softReset: () => resetFn(),
}