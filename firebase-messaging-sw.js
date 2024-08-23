
self.addEventListener('push', function(event) {
    console.log('[Service Worker] Push Received...');
    console.log(`[Service Worker] Push had this data: "${event.data.text()}"`);
    
    const pushData = event.data.json(); // Parse the data from the push event as JSON

    const title = pushData.notification.title;
    
    const options = {
        body: pushData.notification.body,
        actions: [
            {action: 'like', title: 'Like'},
            {action: 'reply', title: 'Reply'}
        ],      
        icon: pushData.notification.icon,
        badge: "https://mir-s3-cdn-cf.behance.net/user/138/940370256681125.5f7c53fb9779b.png",
        image: "https://mir-s3-cdn-cf.behance.net/user/138/940370256681125.5f7c53fb9779b.png",
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
