// Singleton para AdminModal
let AuthorizeFn = $state(() => {});
let RejectFn = $state(() => {});
let OpenFn = $state(() => {});

export const adminDialog = {
  set onAuthorize(fn) {AuthorizeFn = fn},
  set onReject(fn) {RejectFn = fn},
  set onOpen(fn) {OpenFn = fn},
  Authorize: () => AuthorizeFn(),
  Reject: () => RejectFn(),
  open: (...args) => OpenFn(...args)
};
