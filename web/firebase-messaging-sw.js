/* eslint-disable no-undef */
// Firebase Messaging service worker for web push notifications

importScripts('https://www.gstatic.com/firebasejs/9.22.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.22.2/firebase-messaging-compat.js');

// The following config will be replaced at runtime by Firebase initialization in the app.
// For most setups with firebase_options.dart, messaging uses the default app.
// If you need to hardcode, you can mirror your firebase_options here.

self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => event.waitUntil(self.clients.claim()));

try {
  if (!firebase.apps.length) {
    // Initialize with sender id for background messages
    firebase.initializeApp({
      messagingSenderId: '438957453959',
    });
  }
} catch (e) {}

const messaging = firebase.messaging.isSupported ? firebase.messaging() : null;

if (messaging) {
  // Background message handler
  messaging.onBackgroundMessage((payload) => {
    const notification = payload.notification || {};
    const title = notification.title || 'إشعار';
    const options = {
      body: notification.body || '',
      icon: '/icons/Icon-192.png',
      data: payload.data || {},
    };
    self.registration.showNotification(title, options);
  });

  self.addEventListener('notificationclick', function(event) {
    const data = (event.notification && event.notification.data) || {};
    event.notification.close();
    const urlToOpen = self.location.origin + '/#/home';
    event.waitUntil(
      self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
        for (let i = 0; i < clientList.length; i++) {
          const client = clientList[i];
          if ('focus' in client) return client.focus();
        }
        if (self.clients.openWindow) return self.clients.openWindow(urlToOpen);
      })
    );
  });
}
