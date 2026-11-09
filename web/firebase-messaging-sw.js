self.addEventListener('push', (event) => {
  if (!event.data) return;
  const payload = event.data.json();
  if (!payload.notification) return;
  event.waitUntil(self.registration.showNotification(payload.notification.title, {
    body: payload.notification.body,
    icon: 'icons/Icon-192.png',
  }));
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(clients.matchAll({ type: 'window', includeUncontrolled: true }).then((windows) => {
    if (windows.length) {
      windows[0].postMessage('pilah-notification-open');
      return windows[0].focus();
    }
    return clients.openWindow('./?notification=1');
  }));
});
