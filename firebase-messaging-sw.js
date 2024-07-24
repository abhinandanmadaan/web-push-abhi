
self.addEventListener('push', function(event) {
    console.log('[Service Worker] Push Received...');
    console.log(`[Service Worker] Push had this data: "${event.data.text()}"`);
    
    const pushData = event.data.json(); // Parse the data from the push event as JSON

    const title = pushData.notification.title;
    const options = {
        body: pushData.notification.body,
        actions: pushData.notification.actions,
        icon: pushData.notification.icon,
        badge: pushData.notification.badge,
        image: pushData.notification.image,
        data: pushData.notification.data,
        dir: pushData.notification.direction,
        lang: pushData.notification.language,
        renotify: pushData.notification.renotify,
        requireInteraction: pushData.notification.requireInteraction,
        tag: pushData.notification.tag,
        timestamp: pushData.notification.timestampMillis,
        vibrate: pushData.notification.vibrate,
        customData: pushData.notification.customData,
        silent: pushData.notification.silent
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
