export function debounce(fn, delay = 300) {
    let timeout;
    return (...args) => {
        clearTimeout(timeout);
        return new Promise((resolve) => {
            timeout = setTimeout(async () => {
                resolve(await fn(...args));
            }, delay);
        });
    };
}