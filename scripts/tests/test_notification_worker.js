const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

const handlers = {};
const shown = [];
const messages = [];
const client = { postMessage: message => messages.push(message), focus: async () => {} };
const self = {
  addEventListener: (name, callback) => { handlers[name] = callback; },
  registration: { showNotification: async (title, options) => shown.push({ title, ...options }) },
};
vm.runInNewContext(fs.readFileSync('web/firebase-messaging-sw.js', 'utf8'), {
  self, clients: { matchAll: async () => [client] },
});
(async () => {
  let pending;
  handlers.push({ data: { json: () => ({ notification: { title: 'Jadwal', body: 'Ada jadwal' } }) }, waitUntil: p => { pending = p; } });
  await pending;
  assert.equal(shown[0].title, 'Jadwal');
  assert.equal(shown[0].body, 'Ada jadwal');
  handlers.notificationclick({ notification: { close() {} }, waitUntil: p => { pending = p; } });
  await pending;
  assert.deepEqual(messages, ['pilah-notification-open']);
})().catch(error => { console.error(error); process.exitCode = 1; });
