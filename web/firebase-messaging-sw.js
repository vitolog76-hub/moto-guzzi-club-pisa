importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyBuEjLNdUAqZiYmn4rwyK0VwKHFG6my_Rs',
  appId: '1:730640135992:web:eb7d889ee33f5bf18533cd',
  messagingSenderId: '730640135992',
  projectId: 'motoguzziclub-97318',
  authDomain: 'motoguzziclub-97318.firebaseapp.com',
  storageBucket: 'motoguzziclub-97318.firebasestorage.app',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  // Only show notification manually for data-only messages.
  // Messages with a 'notification' payload are auto-displayed by the browser.
  if (payload.notification) return;

  const title = payload.data?.title ?? 'Promemoria evento';
  const body = payload.data?.body ?? '';
  const options = {
    body,
    icon: './icons/Icon-192.png',
    badge: './icons/Icon-192.png',
  };
  self.registration.showNotification(title, options);
});
