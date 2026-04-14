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
  const title = payload.notification?.title ?? 'Promemoria evento';
  const options = {
    body: payload.notification?.body ?? '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
  };
  self.registration.showNotification(title, options);
});
