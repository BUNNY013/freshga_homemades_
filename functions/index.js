const { setGlobalOptions } = require("firebase-functions/v2");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

setGlobalOptions({ region: "asia-south1" });
admin.initializeApp();

exports.sendFollowerNotifications = onDocumentCreated("store_updates/{updateId}", async (event) => {
  const snap = event.data;
  if (!snap) return null;
  const updateData = snap.data();

    // 1. Extract Details
    const storeId = updateData.storeId;
    const storeName = updateData.storeName || "FreshGa Store";
    const productName = updateData.productName || "Product";
    const type = updateData.type || "community_update";
    const price = updateData.price || 0;
    const discountPrice = updateData.discountPrice || 0;
    const imageUrl = updateData.imageUrl || null;

    let notificationTitle = storeName;
    let notificationBody = updateData.description || "Tap to see what's new!";

    // Dynamically format the body based on the update type
    if (type === "offer" && price > 0 && discountPrice > 0 && discountPrice < price) {
      const percentOff = Math.round(((price - discountPrice) / price) * 100);
      notificationBody = `${percentOff}% off on ${productName}!`;
    } else if (type === "new_launch") {
      notificationBody = `New Launch: ${productName} is now available!`;
    } else if (type === "restock") {
      notificationBody = `Back in Stock: ${productName}!`;
    } else if (updateData.title) {
       // Fallback for custom community updates
       notificationBody = `${updateData.title} - ${notificationBody}`;
    }

    if (!storeId) {
      console.log("No storeId found in the update.");
      return null;
    }

    // 2. Find all customers who follow this store
    const followersSnap = await admin.firestore().collection(`stores/${storeId}/followers`).get();

    if (followersSnap.empty) {
      console.log(`No followers found for store ${storeId}.`);
      return null;
    }

    const userIds = [];
    followersSnap.forEach(doc => {
      // document ID is the userId
      userIds.push(doc.id);
    });

    const tokens = [];

    // 3. Fetch fcmTokens for these users from the 'customers' collection
    // Firestore getAll allows fetching up to 100 documents at once
    const chunks = [];
    for (let i = 0; i < userIds.length; i += 100) {
      chunks.push(userIds.slice(i, i + 100));
    }

    for (const chunk of chunks) {
      const refs = chunk.map(id => admin.firestore().collection("customers").doc(id));
      const customerDocs = await admin.firestore().getAll(...refs);
      
      customerDocs.forEach(doc => {
        if (doc.exists) {
          const data = doc.data();
          if (data.fcmToken) {
            tokens.push(data.fcmToken);
          }
        }
      });
    }

    if (tokens.length === 0) {
      console.log("No FCM tokens found for followers.");
      return null;
    }

    // 4. Build the Payload
    const payload = {
      notification: {
        title: notificationTitle,
        body: notificationBody,
      },
      data: {
        updateId: snap.id,
        storeId: storeId,
        productId: updateData.productId || "",
        click_action: "FLUTTER_NOTIFICATION_CLICK"
      }
    };

    // Attach image if available
    if (imageUrl) {
      payload.notification.image = imageUrl;
    }

    // 5. Blast the Notification
    try {
      const response = await admin.messaging().sendEachForMulticast({
        tokens: tokens,
        ...payload
      });
      console.log(response.successCount + " messages were sent successfully.");
    } catch (error) {
      console.error("Error sending push notification:", error);
    }

    return null;
});
