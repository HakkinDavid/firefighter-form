// Singleton para ModalDialog 
let dialogContent = $state(null);

export const dialog = {
  get content() { return dialogContent },
  open: (options) => dialogContent = options,
  close: () => dialogContent = null
};
