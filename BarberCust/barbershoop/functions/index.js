const {onDocumentUpdated} = require("firebase-functions/v2/firestore");
const {setGlobalOptions} = require("firebase-functions/v2");
const admin = require("firebase-admin");

admin.initializeApp();

setGlobalOptions({
  region: "asia-southeast1",
  maxInstances: 10,
});

exports.sendReservationApprovedNotification = onDocumentUpdated(
    "reservations/{reservationId}",
    async (event) => {
      const before = event.data.before.data();
      const after = event.data.after.data();

      // Tidak ada perubahan status
      if (before.status === after.status) {
        return;
      }

      // Hanya Pending -> Approved
      if (
        before.status !== "Pending" ||
      after.status !== "Approved"
      ) {
        return;
      }

      const userId = after.userId;

      if (!userId) {
        console.log("UserId kosong");
        return;
      }

      const userDoc = await admin
          .firestore()
          .collection("users")
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        console.log("User tidak ditemukan");
        return;
      }

      const token = userDoc.data().fcmToken;

      if (!token) {
        console.log("FCM Token kosong");
        return;
      }

      await admin.messaging().send({
        token: token,
        notification: {
          title: "💈 Reservasi Dikonfirmasi",
          body:
          `Reservasi ${after.bookingDate} pukul ${after.bookingTime} telah dikonfirmasi.`,
        },
      });

      console.log("Notifikasi berhasil dikirim");
    },
);
