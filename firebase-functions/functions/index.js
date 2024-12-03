const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Diese Funktion wird bei jeder neuen Nachricht in der "messages"-Sammlung ausgelöst
exports.sendNotificationOnNewMessage = functions.firestore
    .document('chats/{chatID}/messages/{messageID}')
    .onCreate(async (snapshot, context) => {
        const messageData = snapshot.data(); // Holen der Nachrichtendaten
        const chatID = context.params.chatID; // Holen der ChatID
        const messageID = context.params.messageID; // Holen der MessageID

        // Hole den Empfänger-Token (der Token ist im User-Dokument gespeichert)
        const receiverID = messageData.receiverID;
        
        // Holen des FCM-Tokens des Empfängers
        const userDoc = await admin.firestore().collection('users').doc(receiverID).get();
        if (!userDoc.exists) {
            console.log("Benutzer nicht gefunden");
            return null;
        }
        
        const receiverDeviceToken = userDoc.data().fcmToken;
        if (!receiverDeviceToken) {
            console.log("FCM-Token für den Empfänger fehlt");
            return null;
        }

        // Erstelle die Payload für die Benachrichtigung
        const payload = {
            notification: {
                title: `Neue Nachricht von ${messageData.displayName}`,
                body: messageData.message,
                sound: 'default',
            },
            token: receiverDeviceToken, // FCM-Token des Empfängers
        };

        // Versende die Push-Benachrichtigung
        try {
            await admin.messaging().send(payload);
            console.log('Benachrichtigung erfolgreich gesendet');
        } catch (error) {
            console.error('Fehler beim Senden der Benachrichtigung:', error);
        }

        return null;
    });
