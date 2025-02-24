import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

admin.initializeApp();

export const disableUser = functions.https.onCall(
  async (data, context: functions.https.CallableContext) => {
    // check if the request is authenticated
    if (!context?.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "The function must be called while authenticated."
      );
    }

    const uid = data.uid; // get the user ID from the request data

    if (!uid) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "The function must be called with a valid user ID."
      );
    }

    try {
      await admin.auth().updateUser(uid, { disabled: true }); // disable the user
      return { message: `Successfully disabled user with UID: ${uid}` };
    } catch (error) {
      throw new functions.https.HttpsError(
        "internal",
        `Error disabling user: ${(error as Error).message}`
      );
    }
  }
);
