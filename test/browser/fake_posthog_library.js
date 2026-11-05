// A tiny stand-in for PostHog's browser library, so browser tests never touch
// the network. It only records how `posthog.init` was called.
window.posthog = {
  init: function (key, options) {
    window.__initCalls = (window.__initCalls || 0) + 1;
    window.__initArgs = [key, options];
  },
};
