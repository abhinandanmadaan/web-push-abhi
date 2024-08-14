<!DOCTYPE html>
<html lang="en">
<head>
  <title>CCPT-2115 - [ANS] PoC - Web push notifications with Acrobat web.</title>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">

  <script src="https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js" type="module"></script>
  <script src="https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js" type="module"></script>
  <script src="firebase-messaging-sw.js"></script>

  <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.4.1/css/bootstrap.min.css">
  <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.7.1/jquery.min.js"></script>
  <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.4.1/js/bootstrap.min.js"></script>

  <style>
    .bd-example {
        border-color: rgb(222, 226, 230);
        border-style : solid;
        border-width: 1px;
        padding: 5px 15px 5px 15px;
        width: 60%;
        margin-bottom: 10px;
    }
    .h3, h3 {
        margin-top: 5px;
        margin-bottom: 5px;
    }
    .form-text{
      text-align: end;
      color: grey;
    }
    .form-label{
      font-weight: normal;
    }
    .info-bar {
      background-color: #f8f9fa;
      border-bottom: 1px solid #e9ecef;
      padding: 10px;
      text-align: center;
      position: fixed;
      top: 0;
      width: 100%;
      z-index: 1000;
    }
    .info-bar button {
      margin-left: 10px;
    }
  </style>
</head>

<body>
<div class="info-bar" id="infoBar">
  <span>Allow notifications to stay updated.</span>
  <button id="allowNotifications" class="btn btn-primary">Allow Notifications</button>
  <button id="closeInfoBar" class="btn btn-secondary">✕</button>
</div>

<div class="container" style="margin-top: 60px;">
  <h3>Demo for Web push notifications with Acrobat web</h3>
  <br/><br/>
  <div class="bd-example" id="div1">
    <form action="#">
      <div class="form-group">
        <label for="token" class="form-label">Enter Authorization token</label>
        <input type="password" id="token" class="form-control" aria-describedby="tokenHelpBlock" placeholder="Enter IMS User token" value="default">

      </div>
    </form>
  </div> <!-- end of  div1 -->
  <div class="row">
    <div class="col-md-12">
      <label id="webPushIdLabel" style="background-color: yellow;"></label>
      <table id="conversation" class="table table-striped">
        <thead>
        <tr>
          <th>Info!!</th>
        </tr>
        </thead>
        <tbody id="info">
        </tbody>
      </table>
    </div>
  </div>
</div>

<script type="module">
    window.onload = function() {
      const appId = localStorage.getItem('appId') || 'WebPushTestApp';
      const targetId = localStorage.getItem('targetId') || 'default';
      const locale = localStorage.getItem('locale') || 'en_US';
      const browserVersionMin = '1';
      const browserVersionMax = '10';
      const browserName = localStorage.getItem('browserName') || 'Chrome';
      const imsToken = document.getElementById('token').value;
      const apiKey = 'ANS1';

      const wpId = localStorage.getItem(appId);
      const infoBar = document.getElementById('infoBar');
      const allowNotificationsButton = document.getElementById('allowNotifications');
      const closeInfoBarButton = document.getElementById('closeInfoBar');

      if (wpId) {
        infoBar.style.display = 'none';
        $("#info").html(`<tr><td style='word-wrap: break-word'> A subscription already exists for the given appId. The subscription ID is: ${wpId} </td></tr>`);
      }

      closeInfoBarButton.addEventListener('click', function() {
        infoBar.style.display = 'none';
      });

      const firebaseConfig = {
          apiKey: "AIzaSyBQhnlhociHucGdwk5lkqy0gXruyELekAI",
          authDomain: "web-push-demo-99815.firebaseapp.com",
          projectId: "web-push-demo-99815",
          storageBucket: "web-push-demo-99815.appspot.com",
          messagingSenderId: "1059431989933",
          appId: "1:1059431989933:web:842fc48d3f73bb89203c24",
          measurementId: "G-22L57Q8N5Q"
      };

      allowNotificationsButton.addEventListener('click', function(event) {
        event.preventDefault();

        const webPushInfo = {
          appId: appId,
          targetId: targetId,
          locale: locale,
          browserVersionMin: browserVersionMin,
          browserVersionMax: browserVersionMax,
          browserName: browserName
        };

        if ('safari' in window && 'pushNotification' in window.safari) {
          window.safari.pushNotification.requestPermission(
            'https://ans-team-ans-web-push-deploy-ethos501-stage-va6-k-ae8cf7.stage.cloud.adobe.io',
            'web.adobe.ans.test',
            { userId: targetId },
            function(permissionData) {
              if (permissionData.permission === 'denied') {
                console.warn('Push notifications permission denied');
                $("#info").html("<tr><td style='word-wrap: break-word'> Push notifications permission denied. </td></tr>");
              } else if (permissionData.permission === 'granted') {
                infoBar.style.display = 'none';
                const deviceToken = permissionData.deviceToken;
                webPushInfo.registrationToken = deviceToken;

                fetch('https://ans-team-ans-web-push-deploy-ethos501-stage-va6-k-ae8cf7.stage.cloud.adobe.io/subscription', {
                  method: 'POST',
                  headers: {
                    'Content-Type': 'application/json',
                    'x-api-key': apiKey,
                    'Authorization': 'bearer ' + imsToken
                  },
                  body: JSON.stringify(webPushInfo)
                })
                .then(response => response.json())
                .then(data => {
                  const webPushIdLabel = document.getElementById('webPushIdLabel');
                  webPushIdLabel.textContent = `Subscribed successfully with webPushId: ${data.webPushId}`;
                  webPushIdLabel.style.color = 'green';
                  localStorage.setItem(appId, data.webPushId);
                  $("#info").html("<tr><td style='word-wrap: break-word'> Token is : "+ data.registrationToken +" </td></tr>");
                })
                .catch((err) => {
                  console.log('An error occurred while retrieving token. ', err);
                  $("#info").html("<tr><td style='word-wrap: break-word'> An error occurred while retrieving token. </td></tr>");
                });
              }
            }
          );
        } else if ('serviceWorker' in navigator && 'PushManager' in window) {
          navigator.serviceWorker.register('firebase-messaging-sw.js')
            .then(function(swReg) {
              firebase.initializeApp(firebaseConfig);
              const messagingObject = firebase.messaging();

              messagingObject.getToken({
                serviceWorkerRegistration: swReg,
                vapidKey: 'BEmAVlZuKUS6BKpeU4PZg9XFsihcXgfg_4l2MC-9l2El79yKlSlc2RhL1WKEiKwaB8_3JORdF4WL25fC-5M4v1k'
              }).then((currentToken) => {
                if (currentToken) {
                  infoBar.style.display = 'none';
                  webPushInfo.registrationToken = currentToken;
                  fetch('https://ans-team-ans-web-push-deploy-ethos501-stage-va6-k-ae8cf7.stage.cloud.adobe.io/subscription', {
                    method: 'POST',
                    headers: {
                      'Content-Type': 'application/json',
                      'x-api-key': apiKey,
                      'Authorization': 'bearer ' + imsToken
                    },
                    body: JSON.stringify(webPushInfo)
                  })
                  .then(response => response.json())
                  .then(data => {
                    const webPushIdLabel = document.getElementById('webPushIdLabel');
                    webPushIdLabel.textContent = `Subscribed successfully with webPushId: ${data.webPushId}`;
                    webPushIdLabel.style.color = 'green';
                    localStorage.setItem(appId, data.webPushId);
                    $("#info").html("<tr><td style='word-wrap: break-word'> Token is : "+ data.registrationToken +" </td></tr>");
                  })
                  .catch((err) => {
                    console.log('An error occurred while retrieving token. ', err);
                    $("#info").html("<tr><td style='word-wrap: break-word'> An error occurred while retrieving token. </td></tr>");
                  });
                } else {
                  console.log('No registration token available. Request permission to generate one.');
                  $("#info").html("<tr><td style='word-wrap: break-word'> No registration token available. Request permission to generate one. </td></tr>");
                }
              }).catch((err) => {
                console.log('An error occurred while retrieving token. ', err);
                $("#info").html("<tr><td style='word-wrap: break-word'> An error occurred while retrieving token. "+ err +" </td></tr>");
              });
            })
            .catch(function(error) {
              console.error('Service Worker Error', error);
              $("#info").html("<tr><td style='word-wrap: break-word'> Service Worker Error. </td></tr>");
            });
        } else {
          console.warn('Push messaging is not supported');
          $("#info").html("<tr><td style='word-wrap: break-word'> Push messaging is not supported. </td></tr>");
        }
      });
    };
  </script>
</body>
</html>
