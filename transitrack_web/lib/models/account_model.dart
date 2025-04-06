// ignore_for_file: non_constant_identifier_names, avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:transitrack_web/models/feedback_model.dart';
import 'package:transitrack_web/services/find_location.dart';

// Model for Accounts

class AccountData {
  String account_email; // email
  String account_name; // username
  int account_type; // 0 for commuters, 1 for drivers, and 2 for route managers
  String account_id; // Generated Document ID by firestore.
  bool
      account_banned; // used to check if the account is banned or not for commuters
  bool is_verified; // Only used for Driver and Route Manager Accounts.
  int route_id;
  String?
      jeep_driving; // Used for Driver Accounts. If this is empty (""), it means the driver account is currently not operating.
  bool
      show_discounted; // Used to set if we show the discounted or regular fare when there is an account logged in.

  AccountData(
      {required this.account_email,
      required this.account_name,
      required this.account_type,
      required this.is_verified,
      required this.route_id,
      required this.account_id,
      required this.account_banned,
      this.jeep_driving,
      required this.show_discounted});

  factory AccountData.fromSnapshot(DocumentSnapshot<Object?> snapshot,
      {bool isCommuterVerified = false}) {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

    String accountEmail = data['account_email'];
    String accountName = data['account_name'];
    int accountType = data['account_type'];
    bool isVerified = data['is_verified'] as bool;
    int routeId = data['route_id'];
    String? jeepDriving = data['jeep_driving'];
    bool showDiscounted = data['show_discounted'] ?? false;
    String accountId = snapshot.id;
    bool accountBanned = data['account_banned'];

    if (accountType == 0) {
      isVerified = isCommuterVerified;
    }

    return AccountData(
        account_email: accountEmail,
        account_name: accountName,
        account_type: accountType,
        is_verified: isVerified,
        route_id: routeId,
        jeep_driving: jeepDriving,
        show_discounted: showDiscounted,
        account_id: accountId,
        account_banned: accountBanned);
  }

  static Future<AccountData?> getAccountByEmail(String email) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('accounts')
          .where('account_email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return AccountData.fromSnapshot(querySnapshot.docs.first);
      } else {
        return null; // No document found with the given email
      }
    } catch (e) {
      print('Error fetching account data: $e');
      return null;
    }
  }

  static Future<AccountData?> getDriverAccountByJeep(String jeepId) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('accounts')
          .where('account_type', isEqualTo: 1)
          .where('jeep_driving', isEqualTo: jeepId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return AccountData.fromSnapshot(querySnapshot.docs.first);
      } else {
        return null; // No document found with the given email
      }
    } catch (e) {
      print('Error fetching account data: $e');
      return null;
    }
  }

  static Future<bool> updateAccountFirestore(
      String email, Map<String, dynamic> dataToUpdate) async {
    try {
      CollectionReference accountsCollection =
          FirebaseFirestore.instance.collection('accounts');
      QuerySnapshot querySnapshot = await accountsCollection
          .where('account_email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        String docId = querySnapshot.docs.first.id;
        await accountsCollection.doc(docId).update(dataToUpdate);
        return true;
      } else {
        print('No document found with the given email: $email');
        return false;
      }
    } catch (e) {
      print('Error updating account data: $e');
      return false;
    }
  }

  static Future<void> updateEmailAndPassword(
      String newEmail, String newPassword) async {
    try {
      // Get the current user
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Update email
        await user.updateEmail(newEmail);

        // Update password
        if (newPassword != "") {
          await user.updatePassword(newPassword);
        }

        print('Email and password updated successfully.');
      } else {
        // No user signed in
        print('No user signed in.');
      }
    } catch (e) {
      print('Error updating email and password: $e');
    }
  }

  static Future<UsersAdditionalInfo?> loadAccountPairDetails(
      String sender, String recepient,
      {LatLng? location}) async {
    AccountData? senderData = await AccountData.getAccountByEmail(sender);
    AccountData? recepientData = await AccountData.getAccountByEmail(recepient);
    String? address;

    if (location != null) {
      address =
          await findAddress(LatLng(location.latitude, location.longitude));
    }

    return UsersAdditionalInfo(
        senderData: senderData,
        recepientData: recepientData,
        locationData: location != null ? address : null);
  }

  static Map<String, int> accountTypeMap = {
    'Commuter': 0,
    'Driver': 1,
    'Route Manager': 2,
  };

  static List<String> accountType = ['Commuter', 'Driver', 'Route Manager'];
}
