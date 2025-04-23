import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

admin.initializeApp();

export const toggleUserStatus = functions.https.onCall(
  async (
    data: { uid: string; disable: boolean },
    context: functions.https.CallableContext
  ) => {
    // Check if the request is authenticated
    if (!context?.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "The function must be called while authenticated."
      );
    }

    const { uid, disable } = data; // Get the user ID and disable flag from request data

    if (!uid || typeof disable !== "boolean") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "The function must be called with a valid user ID and disable flag."
      );
    }

    try {
      // Update authentication status
      await admin.auth().updateUser(uid, { disabled: disable });

      // Update Firestore account status only for the document where account_uid matches uid
      const accountsRef = admin.firestore().collection("accounts");
      const querySnapshot = await accountsRef
        .where("account_uid", "==", uid)
        .get();

      if (!querySnapshot.empty) {
        querySnapshot.forEach(async (doc) => {
          await doc.ref.set({ account_banned: disable }, { merge: true });
        });
      }

      return {
        message: `Successfully ${
          disable ? "disabled" : "enabled"
        } user with UID: ${uid}`,
      };
    } catch (error) {
      throw new functions.https.HttpsError(
        "internal",
        `Error updating user status: ${(error as Error).message}`
      );
    }
  }
);
