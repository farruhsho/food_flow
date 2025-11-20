importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: 'AIzaSyBn-2t26qoKRJ7auM7tF3OzvOxGJJ5x-Mw',
      appId: '1:135333269617:web:ce2e1df50f1532057e0bd0',
      messagingSenderId: '135333269617',
      projectId: 'foodflow-78f01',
      authDomain: 'foodflow-78f01.firebaseapp.com',
      databaseURL: 'https://foodflow-78f01-default-rtdb.firebaseio.com',
      storageBucket: 'foodflow-78f01.firebasestorage.app',
      measurementId: 'G-6MWN8QWNE7',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((message) => {
  console.log("Background message:", message);
});