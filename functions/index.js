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
        if (data.fcmToken) tokens.push(data.fcmToken);
        if (Array.isArray(data.fcmTokens)) tokens.push(...data.fcmTokens);
      }
    });
  }

  if (tokens.length === 0) {
    console.log("No FCM tokens found for followers, but we will still save in-app notifications.");
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

  // 5. Save to In-App Notifications (if high value)
  if (type === "offer" || type === "new_launch") {
    const db = admin.firestore();
    let chunkedBatches = [];
    let currentBatch = db.batch();
    let opCount = 0;

    for (const followerId of userIds) {
      const notifRef = db.collection("customers").doc(followerId).collection("notifications").doc();
      currentBatch.set(notifRef, {
        title: notificationTitle,
        message: notificationBody,
        type: "promo",
        storeId: storeId,
        productId: updateData.productId || null,
        imageUrl: imageUrl || null,
        isUnread: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });
      opCount++;

      if (opCount === 450) {
        chunkedBatches.push(currentBatch.commit());
        currentBatch = db.batch();
        opCount = 0;
      }
    }

    if (opCount > 0) {
      chunkedBatches.push(currentBatch.commit());
    }

    try {
      await Promise.all(chunkedBatches);
      console.log(`Saved in-app notifications for ${userIds.length} followers.`);
    } catch (err) {
      console.error("Error saving in-app notifications:", err);
    }
  }

  // 6. Blast the Push Notification
  if (tokens.length > 0) {
    try {
      const response = await admin.messaging().sendEachForMulticast({
        tokens: tokens,
        ...payload
      });
      console.log(response.successCount + " push messages were sent successfully.");
    } catch (error) {
      console.error("Error sending push notification:", error);
    }
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

  const tokens = [];
  if (userSnap.exists) {
    const data = userSnap.data();
    if (data.fcmToken) tokens.push(data.fcmToken);
    if (Array.isArray(data.fcmTokens)) tokens.push(...data.fcmTokens);
  }
  const uniqueTokens = [...new Set(tokens)];

  // Save to DB for Vendor
  const vendorNotification = {
    vendorId: ownerId,
    title: "New Order Received! 🚨",
    message: `You have a new order (#${orderData.orderId.substring(0, 8)}) for ₹${orderData.totalAmount}.`,
    type: "order",
    relatedId: orderData.orderId,
    isRead: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  try {
    await admin.firestore().collection("notifications").add(vendorNotification);
  } catch (error) {
    console.error("Error saving vendor notification to DB:", error);
  }

  if (uniqueTokens.length > 0) {
    const payload = {
      notification: {
        title: vendorNotification.title,
        body: vendorNotification.message,
      },
      data: {
        orderId: orderData.orderId,
        click_action: "FLUTTER_NOTIFICATION_CLICK"
      },
      android: {
        priority: "high",
        notification: { sound: "default", channelId: "high_importance_channel" }
      },
      apns: {
        payload: { aps: { sound: "default" } }
      }
    };

    try {
      await admin.messaging().sendEachForMulticast({
        tokens: uniqueTokens,
        ...payload
      });
    } catch (error) {
      console.error("Error sending order notification to vendor:", error);
    }
  }

  // Notify the Customer
  const customerId = orderData.customerId;
  const storeName = storeData.storeName || "FreshGa Store";

  if (customerId) {
    const title = "Order Placed Successfully! 🎉";
    const body = `Your order #${orderData.orderId.substring(0, 8)} from ${storeName} has been placed. Waiting for the kitchen to accept it.`;

    // Save to database
    const notificationData = {
      title: title,
      message: body,
      type: "order_update",
      orderId: orderData.orderId,
      isUnread: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    try {
      await admin.firestore().collection("customers").doc(customerId).collection("notifications").add(notificationData);
    } catch (error) {
      console.error("Error saving order placed notification to DB:", error);
    }

    const customerSnap = await admin.firestore().collection("customers").doc(customerId).get();

    const tokens = [];
    if (customerSnap.exists) {
      const data = customerSnap.data();
      if (data.fcmToken) tokens.push(data.fcmToken);
      if (Array.isArray(data.fcmTokens)) tokens.push(...data.fcmTokens);
    }
    const uniqueTokens = [...new Set(tokens)];

    if (uniqueTokens.length > 0) {
      const customerPayload = {
        notification: {
          title: title,
          body: body,
        },
        data: {
          type: "order_update",
          orderId: orderData.orderId,
          click_action: "FLUTTER_NOTIFICATION_CLICK"
        },
        android: {
          priority: "high",
          notification: { sound: "default", channelId: "high_importance_channel" }
        },
        apns: {
          payload: { aps: { sound: "default" } }
        }
      };

      try {
        await admin.messaging().sendEachForMulticast({
          tokens: uniqueTokens,
          ...customerPayload
        });
      } catch (error) {
        console.error("Error sending order placed notification to customer:", error);
      }
    }
  }

  return null;
});

exports.onOrderStatusUpdated = onDocumentUpdated("orders/{orderId}", async (event) => {
  const beforeData = event.data.before.data();
  const afterData = event.data.after.data();

  if (beforeData.orderStatus === afterData.orderStatus) {
    return null; // Status didn't change
  }

  const orderStatus = afterData.orderStatus;
  const customerId = afterData.customerId;
  let storeName = afterData.storeName || "Store";
  const fullOrderId = afterData.orderId;

  // Fetch real store name if possible
  if (afterData.storeId) {
    try {
      const storeSnap = await admin.firestore().collection("stores").doc(afterData.storeId).get();
      if (storeSnap.exists && storeSnap.data().storeName) {
        storeName = storeSnap.data().storeName;
      }
    } catch (e) {
      console.error("Error fetching store info", e);
    }
  }

  let title = "Order Update";
  let body = `Your order #${fullOrderId} is now ${orderStatus}.`;

  switch (orderStatus) {
    case "Accepted":
      title = "Order Accepted! 🎉";
      body = `${storeName} has accepted your order #${fullOrderId} and is preparing it now.`;
      break;
    case "Shipped":
      title = "Order Shipped! 🚚";
      let shippingText = "is on its way!";
      if (afterData.shippingProvider) {
        shippingText = `has been shipped via ${afterData.shippingProvider}`;
        if (afterData.trackingId) {
          shippingText += ` (Tracking ID: ${afterData.trackingId})`;
        }
      }
      body = `Your order #${fullOrderId} from ${storeName} ${shippingText}`;
      break;
    case "Delivered":
      title = "Order Delivered! ✅";
      body = `Your order #${fullOrderId} from ${storeName} has been delivered. Enjoy your homemade treats!`;
      break;
    case "Cancelled":
    case "Declined":
      title = "Order Cancelled ❌";
      body = `Your order #${fullOrderId} from ${storeName} has been cancelled.`;
      break;
    case "Packed":
    case "New":
      // Do not send push notifications for these transitional statuses
      return null;
  }

  // 1. Save notification to database for in-app history
  const notificationData = {
    title: title,
    message: body,
    type: "order_update",
    orderId: afterData.orderId,
    isUnread: true,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  try {
    await admin.firestore().collection("customers").doc(customerId).collection("notifications").add(notificationData);
  } catch (error) {
    console.error("Error saving notification to DB:", error);
  }

  // 2. Send push notification if token exists
  const customerSnap = await admin.firestore().collection("customers").doc(customerId).get();

  const tokens = [];
  if (customerSnap.exists) {
    const data = customerSnap.data();
    if (data.fcmToken) tokens.push(data.fcmToken);
    if (Array.isArray(data.fcmTokens)) tokens.push(...data.fcmTokens);
  }
  const uniqueTokens = [...new Set(tokens)];

  if (uniqueTokens.length === 0) return null;

  const payload = {
    notification: {
      title: title,
      body: body,
    },
    data: {
      type: "order_update",
      orderId: afterData.orderId,
      click_action: "FLUTTER_NOTIFICATION_CLICK"
    },
    android: {
      priority: "high",
      notification: {
        sound: "default",
        channelId: "high_importance_channel"
      }
    },
    apns: {
      payload: {
        aps: {
          sound: "default"
        }
      }
    }
  };

  try {
    await admin.messaging().sendEachForMulticast({
      tokens: uniqueTokens,
      ...payload
    });
  } catch (error) {
    console.error("Error sending order update to customer:", error);
  }

  // Notify Vendor if Cancelled
  if (orderStatus === "Cancelled" || orderStatus === "Declined") {
    const storeId = afterData.storeId;
    if (storeId) {
      try {
        const storeSnap = await admin.firestore().collection("stores").doc(storeId).get();
        if (storeSnap.exists) {
          const ownerId = storeSnap.data().ownerId;
          const userSnap = await admin.firestore().collection("users").doc(ownerId).get();

          const tokens = [];
          if (userSnap.exists) {
            const data = userSnap.data();
            if (data.fcmToken) tokens.push(data.fcmToken);
            if (Array.isArray(data.fcmTokens)) tokens.push(...data.fcmTokens);
          }
          const uniqueTokens = [...new Set(tokens)];

          const vendorNotification = {
            vendorId: ownerId,
            title: "Order Cancelled ❌",
            message: `Order #${fullOrderId} has been cancelled. Do not prepare.`,
            type: "alert",
            relatedId: afterData.orderId,
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          };

          await admin.firestore().collection("notifications").add(vendorNotification);

          if (uniqueTokens.length > 0) {
            await admin.messaging().sendEachForMulticast({
              tokens: uniqueTokens,
              notification: { title: vendorNotification.title, body: vendorNotification.message },
              data: { orderId: afterData.orderId, type: "order_cancelled", click_action: "FLUTTER_NOTIFICATION_CLICK" },
              android: { priority: "high", notification: { sound: "default", channelId: "high_importance_channel" } },
              apns: { payload: { aps: { sound: "default" } } }
            });
          }
        }
      } catch (err) {
        console.error("Error sending cancellation to vendor:", err);
      }
    }
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

exports.vendorSLAWarnings = onSchedule("every 15 minutes", async (event) => {
  const db = admin.firestore();
  const now = admin.firestore.Timestamp.now();
  const nowMs = now.toDate().getTime();

  let count = 0;

  // 1. Accept Warnings (1 hour left)
  const newOrdersSnap = await db.collection("orders")
    .where("orderStatus", "==", "New")
    .get();

  for (const doc of newOrdersSnap.docs) {
    const order = doc.data();
    if (!order.expiresAt || order.vendorAcceptWarningSent === true) continue;

    const expiresMs = order.expiresAt.toDate().getTime();
    const hoursLeft = (expiresMs - nowMs) / (1000 * 60 * 60);

    if (hoursLeft <= 1 && hoursLeft > 0) {
      await doc.ref.update({ vendorAcceptWarningSent: true });

      const storeSnap = await db.collection("stores").doc(order.storeId).get();
      if (!storeSnap.exists) continue;
      const ownerId = storeSnap.data().ownerId;

      const title = "Urgent: Accept Order! ⏳";
      const body = `Order #${order.orderId.substring(0, 8)} expires in ${Math.floor(hoursLeft)} hours. Accept it now!`;

      await db.collection("notifications").add({
        vendorId: ownerId,
        title: title,
        message: body,
        type: "alert",
        relatedId: order.orderId,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      const userSnap = await db.collection("users").doc(ownerId).get();
      const tokens = [];
      if (userSnap.exists) {
        const data = userSnap.data();
        if (data.fcmToken) tokens.push(data.fcmToken);
        if (Array.isArray(data.fcmTokens)) tokens.push(...data.fcmTokens);
      }
      const uniqueTokens = [...new Set(tokens)];

      if (uniqueTokens.length > 0) {
        await admin.messaging().sendEachForMulticast({
          tokens: uniqueTokens,
          notification: { title: title, body: body },
          data: { orderId: order.orderId, click_action: "FLUTTER_NOTIFICATION_CLICK" },
          android: { priority: "high" }
        }).catch(e => console.error(e));
      }
      count++;
    }
  }

  // 2. Dispatch Overdue Warning (Past max dispatch date)
  const acceptedOrdersSnap = await db.collection("orders")
    .where("orderStatus", "in", ["Accepted", "Packed"])
    .get();

  for (const doc of acceptedOrdersSnap.docs) {
    const order = doc.data();
    if (!order.maxDispatchDate || order.vendorDispatchWarningSent === true) continue;

    const dispatchMs = order.maxDispatchDate.toDate().getTime();
    const hoursLeft = (dispatchMs - nowMs) / (1000 * 60 * 60);

    if (hoursLeft <= 0) {
      await doc.ref.update({ vendorDispatchWarningSent: true });

      const storeSnap = await db.collection("stores").doc(order.storeId).get();
      if (!storeSnap.exists) continue;
      const ownerId = storeSnap.data().ownerId;

      const title = "OVERDUE: Dispatch Immediately! 🚨";
      const body = `Order #${order.orderId.substring(0, 8)} is overdue for dispatch. Please ship immediately!`;

      await db.collection("notifications").add({
        vendorId: ownerId,
        title: title,
        message: body,
        type: "alert",
        relatedId: order.orderId,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      const userSnap = await db.collection("users").doc(ownerId).get();
      const tokens = [];
      if (userSnap.exists) {
        const data = userSnap.data();
        if (data.fcmToken) tokens.push(data.fcmToken);
        if (Array.isArray(data.fcmTokens)) tokens.push(...data.fcmTokens);
      }
      const uniqueTokens = [...new Set(tokens)];

      if (uniqueTokens.length > 0) {
        await admin.messaging().sendEachForMulticast({
          tokens: uniqueTokens,
          notification: { title: title, body: body },
          data: { orderId: order.orderId, click_action: "FLUTTER_NOTIFICATION_CLICK" },
          android: { priority: "high" }
        }).catch(e => console.error(e));
      }
      count++;
    }
  }

  if (count > 0) console.log(`Sent ${count} SLA warnings to vendors.`);
});

/**
 * Triggered when a new review is added to the "reviews" collection.
 */
exports.updateStoreRating = onDocumentCreated('reviews/{reviewId}', async (event) => {
  const snap = event.data;
  if (!snap) return null;
  const newReview = snap.data();
  const storeId = newReview.storeId;
  const newReviewRating = newReview.rating;

  // If the review is missing crucial data, abort.
  if (!storeId || typeof newReviewRating !== 'number') {
    console.log('Review is missing storeId or rating.');
    return null;
  }

  const storeRef = admin.firestore().collection('stores').doc(storeId);

  try {
    // We use a Firestore Transaction to ensure data consistency
    await admin.firestore().runTransaction(async (transaction) => {
      const storeDoc = await transaction.get(storeRef);

      if (!storeDoc.exists) {
        throw new Error('Store does not exist!');
      }

      const storeData = storeDoc.data();

      // Fetch current values, defaulting to 0 if they don't exist yet
      const oldRating = storeData.rating || 0.0;
      const oldTotalReviews = storeData.totalReviews || 0;

      // Calculate the new weighted average
      const newTotalReviews = oldTotalReviews + 1;
      const newRating = ((oldRating * oldTotalReviews) + newReviewRating) / newTotalReviews;

      // Update the store document with the new values
      transaction.update(storeRef, {
        rating: newRating,
        totalReviews: newTotalReviews,
      });
    });

    console.log(`Successfully updated store ${storeId} to rating ${newRating}`);
    return null;

  } catch (error) {
    console.error('Error updating store rating:', error);
    return null;
  }
});

