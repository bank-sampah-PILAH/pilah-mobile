// A tiny stand-in for PostHog's browser library, so browser tests never touch
// the network. It only records how it was called, in order, in window.__calls.
window.__calls = [];
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
};
