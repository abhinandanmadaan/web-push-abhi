
self.addEventListener('push', function(event) {
    console.log('[Service Worker] Push Received...');
    console.log(`[Service Worker] Push had this data: "${event.data.text()}"`);
    
    const pushData = event.data.json(); // Parse the data from the push event as JSON

    const title = pushData.title;
    const options = {
        body: pushData.body,
        icon: pushData.icon
    };

    event.waitUntil(self.registration.showNotification(title, options));
});

self.addEventListener('notificationclick', function(event) {
    console.log('[Service Worker] Notification click received.');

    event.notification.close();

    event.waitUntil(
        clients.openWindow('https://developers.google.com/web')
    );
});
