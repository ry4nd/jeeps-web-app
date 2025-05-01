import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:transitrack_web/components/account_related/account_settings.dart';
import 'package:transitrack_web/style/style.dart';

import '../../models/account_model.dart';
import '../../style/constants.dart';
import 'login_signup_form.dart';

// This widget listens whether there is a logged in account or not.

class AccountStream extends StatefulWidget {
  User? currentUser;
  AccountData? user;
  LatLng? deviceLoc;
  String? admin;
  int route;
  AccountStream(
      {super.key,
      required this.currentUser,
      required this.user,
      required this.deviceLoc,
      this.admin,
      required this.route});

  @override
  State<AccountStream> createState() => _AccountStreamState();
}

class _AccountStreamState extends State<AccountStream> {
  @override
  Widget build(BuildContext context) {
    // LOGGED IN
    if (widget.currentUser != null) {
      if (widget.user != null) {
        return Container(
            width: double.maxFinite,
            padding: const EdgeInsets.all(Constants.defaultPadding),
            margin: const EdgeInsets.symmetric(
                horizontal: Constants.defaultPadding),
            decoration: BoxDecoration(
              border: Border.all(width: 2, color: Colors.white),
              borderRadius: const BorderRadius.all(
                  Radius.circular(Constants.defaultPadding)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        PrimaryText(
                            text: widget.user!.account_name,
                            color: Colors.white,
                            fontWeight: FontWeight.w700),
                        const SizedBox(width: Constants.defaultPadding / 2),
                        Icon(
                            widget.user!.is_verified
                                ? Icons.verified_user
                                : Icons.remove_moderator,
                            color: widget.user!.is_verified
                                ? Colors.blue
                                : Colors.grey,
                            size: 15)
                      ],
                    ),
                    GestureDetector(
                        onTap: () async {
                          AwesomeDialog(
                            width: 500,
                            context: context,
                            dialogType: DialogType.noHeader,
                            body: PointerInterceptor(
                              child: AccountSettings(
                                  user: widget.currentUser!,
                                  account: widget.user!),
                            ),
                          ).show();
                        },
                        child: const Icon(Icons.settings, color: Colors.white))
                  ],
                ),
                Text(
                    "${widget.user!.account_type > 0 ? widget.admin : ''}${AccountData.accountType[widget.user!.account_type]}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: Constants.defaultPadding),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        setState(() {
                          FirebaseAuth.instance.signOut();
                        });
                      },
                      child: const Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Icon(Icons.logout, color: Colors.white),
                            SizedBox(width: Constants.defaultPadding),
                            Text(
                              'Logout',
                              style: TextStyle(color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          ]),
                    ),
                  ],
                ),
              ],
            ));
      } else {
        return const Center(child: CircularProgressIndicator());
      }
    }
    // NOT logged in
    else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
              child: GestureDetector(
                  onTap: () async {
                    setState(() {
                      AwesomeDialog(
                              width: 500,
                              context: context,
                              dialogType: DialogType.noHeader,
                              body: PointerInterceptor(
                                  child: const LoginSignupForm()))
                          .show();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(Constants.defaultPadding),
                    margin: const EdgeInsets.symmetric(
                        horizontal: Constants.defaultPadding),
                    decoration: BoxDecoration(
                      border: Border.all(width: 2, color: Colors.white),
                      borderRadius: const BorderRadius.all(
                          Radius.circular(Constants.defaultPadding)),
                    ),
                    child: const Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.account_box,
                                        color: Colors.white),
                                    SizedBox(
                                        width: Constants.defaultPadding / 3),
                                    Text(
                                      'Login',
                                      style: TextStyle(color: Colors.white),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  ]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )))
        ],
      );
    }
  }
}
