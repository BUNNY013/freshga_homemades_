const { setGlobalOptions } = require("firebase-functions/v2");
const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
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

exports.onOrderCreated = onDocumentCreated("orders/{orderId}", async (event) => {
  const snap = event.data;
  if (!snap) return null;
  const orderData = snap.data();

  const storeId = orderData.storeId;
  const storeSnap = await admin.firestore().collection("stores").doc(storeId).get();
  if (!storeSnap.exists) return null;
  
  const storeData = storeSnap.data();
  const ownerId = storeData.ownerId;
  
  const userSnap = await admin.firestore().collection("users").doc(ownerId).get();
  if (!userSnap.exists || !userSnap.data().fcmToken) return null;

  const payload = {
    notification: {
      title: "New Order Received!",
      body: `You have a new order (#${orderData.orderId.substring(0,8)}) for ₹${orderData.totalAmount}.`,
    },
    data: {
      orderId: orderData.orderId,
      click_action: "FLUTTER_NOTIFICATION_CLICK"
    }
  };

  try {
    await admin.messaging().send({
      token: userSnap.data().fcmToken,
      ...payload
    });
  } catch (error) {
    console.error("Error sending order notification to vendor:", error);
  }
  return null;
});

exports.onOrderStatusUpdated = onDocumentUpdated("orders/{orderId}", async (event) => {
  const beforeData = event.data.before.data();
  const afterData = event.data.after.data();

  if (beforeData.orderStatus === afterData.orderStatus) {
    return null; // Status didn't change
  }

  const customerId = afterData.customerId;
  const customerSnap = await admin.firestore().collection("customers").doc(customerId).get();
  if (!customerSnap.exists || !customerSnap.data().fcmToken) return null;

  const payload = {
    notification: {
      title: "Order Update",
      body: `Your order #${afterData.orderId.substring(0,8)} is now ${afterData.orderStatus}.`,
    },
    data: {
      orderId: afterData.orderId,
      click_action: "FLUTTER_NOTIFICATION_CLICK"
    }
  };

  try {
    await admin.messaging().send({
      token: customerSnap.data().fcmToken,
      ...payload
    });
  } catch (error) {
    console.error("Error sending order update to customer:", error);
  }
  return null;
});

exports.scheduledSLACheck = onSchedule("every 15 minutes", async (event) => {
  const now = admin.firestore.Timestamp.now();
  
  const snapshot = await admin.firestore().collection("orders")
    .where("orderStatus", "==", "New")
    .where("expiresAt", "<", now)
    .get();

  if (snapshot.empty) {
    return null;
  }

  const batch = admin.firestore().batch();
  snapshot.docs.forEach(doc => {
    const data = doc.data();
    const timeline = data.timeline || [];
    timeline.push({
      status: "Auto-Cancelled",
      time: new Date().toISOString(),
      note: "Order auto-cancelled as store did not accept within 24 hours."
    });

    batch.update(doc.ref, {
      orderStatus: "Auto-Cancelled",
      timeline: timeline,
      updatedAt: new Date().toISOString()
    });
  });

  try {
    await batch.commit();
    console.log(`Auto-cancelled ${snapshot.docs.length} orders.`);
  } catch (error) {
    console.error("Error auto-cancelling orders:", error);
  }
});

exports.autoMarkDelivered = onSchedule("every 12 hours", async (event) => {
  const now = admin.firestore.Timestamp.now();
  
  // Find all orders that are currently "Shipped"
  const snapshot = await admin.firestore().collection("orders")
    .where("orderStatus", "==", "Shipped")
    .get();

  if (snapshot.empty) {
    return null;
  }

  const batch = admin.firestore().batch();
  let count = 0;

  snapshot.docs.forEach(doc => {
    const order = doc.data();
    if (!order.maxDispatchDate) return;

    // Expected Delivery Date = maxDispatchDate + 5 days
    // Add 1 extra day as a grace period
    const maxDispatchDate = order.maxDispatchDate.toDate();
    const autoDeliveryDate = new Date(maxDispatchDate.getTime() + (6 * 24 * 60 * 60 * 1000)); 

    if (now.toDate() > autoDeliveryDate) {
      const timeline = order.timeline || [];
      timeline.push({
        status: "Delivered",
        time: new Date().toISOString(),
        note: "Auto-marked as delivered by the system."
      });

      batch.update(doc.ref, {
        orderStatus: "Delivered",
        timeline: timeline,
        updatedAt: new Date().toISOString()
      });
      count++;
    }
  });

  if (count > 0) {
    try {
      await batch.commit();
      console.log(`Auto-marked ${count} shipped orders as Delivered.`);
    } catch (error) {
      console.error("Error auto-delivering orders:", error);
    }
  }
});

