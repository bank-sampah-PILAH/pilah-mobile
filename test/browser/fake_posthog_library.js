// A tiny stand-in for PostHog's browser library, so browser tests never touch
// the network. It only records how it was called, in order, in window.__calls.
window.__calls = [];
window.__captures = [];
window.__identified = [];
window.__registered = [];
window.posthog = {
  init: function (key, options) {
    window.__calls.push('init');
    window.__initCalls = (window.__initCalls || 0) + 1;
    window.__initArgs = [key, options];
  },
  opt_out_capturing: function () { window.__calls.push('opt_out_capturing'); },
  opt_in_capturing: function (options) {
    window.__calls.push('opt_in_capturing');
    window.__optInOptions = (window.__optInOptions || []).concat([options]);
  },
  capture: function (event, props) {
    window.__calls.push('capture');
    window.__captures.push([event, props]);
  },
  identify: function (id) {
    window.__calls.push('identify');
    window.__identified.push(id);
  },
  register: function (props) {
    window.__calls.push('register');
    window.__registered.push(props);
  },
  reset: function () { window.__calls.push('reset'); },
};
