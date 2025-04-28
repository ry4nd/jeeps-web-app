import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:provider/provider.dart';
import 'package:transitrack_web/components/left_drawer/desktop_research_prompt.dart';
import 'package:transitrack_web/components/left_drawer/live_test_instructions.dart';
import 'package:transitrack_web/components/left_drawer/mobile_research_prompt.dart';
import '../MenuController.dart';

import '../components/account_related/account_stream.dart';
import '../components/header.dart';
import '../components/left_drawer/logo.dart';
import '../components/map_related/map.dart';
import '../components/left_drawer/route_list.dart';
import '../config/responsive.dart';
import '../models/account_model.dart';
import '../models/jeep_model.dart';
import '../models/route_model.dart';
import '../style/constants.dart';

// The one and only page of the app. This .dart file includes stream set up for the user account, routes, and puvs.

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  bool mobileTutorial = false;
  bool drawerOpen = false;

  // Keeps track of the current FirebaseAuth information
  User? currentUserAuth;

  // Keeps track of the current Firebase Firestore information
  AccountData? currentUserFirestore;

  // All Enabled Routes
  List<RouteData> _routes = [];

  // All PUVs in selected Route
  List<JeepsAndDrivers> jeeps = [];

  // All Drivers that are Operating
  List<AccountData?> drivers = [];

  // Stream Listeners
  late StreamSubscription<User?> userAuthStream;
  late StreamSubscription userFirestoreStream;
  late StreamSubscription routesFirestoreStream;
  late StreamSubscription jeepsFirestoreStream;
  late StreamSubscription driversFirestoreStream;

  // Route Selection (unselected = -1)
  int routeChoice = -1;

  // Device Location Found
  LatLng? deviceLoc;

  // Ensure map is loaded
  bool mapLoaded = false;

  // Ensure GPS Permission is allowed
  bool gpsPermission = false;

  // Upon initialization, load the current user (if there is) and load the firestore information of this user.
  // Also start listening for all enabled routes.
  @override
  void initState() {
    super.initState();
    currentUserAuth = FirebaseAuth.instance.currentUser;
    listenToUserAuth();
    listenToRoutesFirestore();
  }

  void hovering() {
    setState(() {
      drawerOpen = !drawerOpen;
    });
  }

  void switchRoute(int choice) {
    if (routeChoice != -1) {
      jeepsFirestoreStream.cancel();
      driversFirestoreStream.cancel();
    }

    setState(() {
      routeChoice = choice;
    });

    if (routeChoice != -1) {
      drivers.clear();
      jeeps.clear();
      listenToDriversFirestore();
      listenToJeepsFirestore();
    } else {
      jeepsFirestoreStream.cancel();
      driversFirestoreStream.cancel();
    }
  }

  void listenToDriversFirestore() {
    driversFirestoreStream = FirebaseFirestore.instance
        .collection('accounts')
        .where('account_type', isEqualTo: 1)
        .orderBy('account_email')
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          drivers = snapshot.docs
              .map((doc) => AccountData.fromSnapshot(doc))
              .toList();
        });

        List<JeepsAndDrivers> collected = [];

        for (JeepsAndDrivers jeep in jeeps) {
          bool found = drivers
              .any((driver) => driver!.jeep_driving == jeep.jeep.device_id);
          collected.add(JeepsAndDrivers(
              driver: found
                  ? drivers.firstWhere(
                      (driver) => driver!.jeep_driving == jeep.jeep.device_id)
                  : null,
              jeep: jeep.jeep));
        }
        setState(() {
          jeeps = collected;
        });
      }
    });
  }

  void listenToUserAuth() async {
    userAuthStream = FirebaseAuth.instance.authStateChanges().listen(
      (user) {
        setState(() {
          currentUserAuth = user;
        });

        if (currentUserAuth != null) {
          listenToUserFirestore();
        } else {
          setState(() {
            currentUserFirestore = null;
          });
        }

        if (routeChoice != -1) {
          switchRoute(-1);
        }
      },
    );
  }

  void listenToUserFirestore() {
    userFirestoreStream = FirebaseFirestore.instance
        .collection('accounts')
        .where('account_email', isEqualTo: currentUserAuth?.email!)
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          currentUserFirestore = AccountData.fromSnapshot(snapshot.docs.first,
              isCommuterVerified: currentUserAuth!.emailVerified);
        });
      }
    });
  }

  void listenToRoutesFirestore() {
    routesFirestoreStream = FirebaseFirestore.instance
        .collection('routes')
        .orderBy('route_id')
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _routes =
              snapshot.docs.map((doc) => RouteData.fromFirestore(doc)).toList();
        });
      }
    });
  }

  void listenToJeepsFirestore() {
    jeepsFirestoreStream = FirebaseFirestore.instance
        .collection('jeeps_realtime')
        .where('route_id', isEqualTo: routeChoice)
        .orderBy('device_id')
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      if (snapshot.docs.isNotEmpty) {
        List<JeepsAndDrivers> collected = [];
        List<JeepData> _jeeps = [];
        setState(() {
          _jeeps =
              snapshot.docs.map((doc) => JeepData.fromSnapshot(doc)).toList();
        });
        for (JeepData _jeep in _jeeps) {
          bool found =
              drivers.any((driver) => driver!.jeep_driving == _jeep.device_id);
          collected.add(JeepsAndDrivers(
              driver: found
                  ? drivers.firstWhere(
                      (driver) => driver!.jeep_driving == _jeep.device_id)
                  : null,
              jeep: _jeep));
        }
        setState(() {
          jeeps = collected;
        });
      }
    });
  }

  @override
  void dispose() {
    userAuthStream.cancel();
    userFirestoreStream.cancel();
    routesFirestoreStream.cancel();
    jeepsFirestoreStream.cancel();
    driversFirestoreStream.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      onDrawerChanged: (isOpened) {
        setState(() {
          drawerOpen = isOpened;
        });
      },
      key: context.read<MenuControllers>().scaffoldKey,
      drawer: PointerInterceptor(
        child: Drawer(
            shape: const Border(),
            elevation: 0.0,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const DrawerHeader(child: Logo()),
                  if (!mapLoaded || _routes.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: Constants.defaultPadding),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  if (mapLoaded && _routes.isNotEmpty)
                    RouteList(
                        routeChoice: routeChoice,
                        routes: _routes,
                        user: currentUserFirestore,
                        newRouteChoice: (int choice) {
                          if (routeChoice == choice) {
                            switchRoute(-1);
                          } else {
                            switchRoute(choice);
                          }
                        },
                        hoverToggle: hovering),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Constants.defaultPadding),
                      child: const Divider()),
                  const SizedBox(height: Constants.defaultPadding),
                  AccountStream(
                    currentUser: currentUserAuth,
                    user: currentUserFirestore,
                    deviceLoc: deviceLoc,
                    admin: currentUserFirestore != null &&
                            currentUserFirestore!.is_verified &&
                            currentUserFirestore!.route_id >= 0
                        ? "${_routes[currentUserFirestore!.route_id].routeName} "
                        : "",
                    route: routeChoice,
                  ),
                  const SizedBox(height: Constants.defaultPadding),
                  MobileResearchPrompt(),
                  const SizedBox(height: Constants.defaultPadding)
                ],
              ),
            )),
      ),
      body: SafeArea(
        child: Row(
          children: [
            if (Responsive.isDesktop(context))
              Expanded(
                flex: 1,
                child: Drawer(
                  shape: const Border(),
                  elevation: 0.0,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const DrawerHeader(
                          child: Logo(),
                        ),
                        if (!mapLoaded || _routes.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: Constants.defaultPadding),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        if (mapLoaded && _routes.isNotEmpty)
                          RouteList(
                              routeChoice: routeChoice,
                              routes: _routes,
                              user: currentUserFirestore,
                              newRouteChoice: (int choice) {
                                if (routeChoice == choice) {
                                  switchRoute(-1);
                                } else {
                                  switchRoute(choice);
                                }
                              },
                              hoverToggle: hovering),
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: Constants.defaultPadding),
                            child: const Divider()),
                        const SizedBox(height: Constants.defaultPadding),
                        AccountStream(
                          currentUser: currentUserAuth,
                          user: currentUserFirestore,
                          deviceLoc: deviceLoc,
                          admin: currentUserFirestore != null &&
                                  currentUserFirestore!.is_verified &&
                                  currentUserFirestore!.route_id >= 0
                              ? "${_routes[currentUserFirestore!.route_id].routeName} "
                              : "",
                          route: routeChoice,
                        ),
                        const SizedBox(
                          height: Constants.defaultPadding,
                        ),
                        const DesktopResearchPrompt()
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(
              flex: 5,
              child: Stack(children: [
                MapWidget(
                  route: routeChoice == -1 ? null : _routes[routeChoice],
                  jeeps: routeChoice == -1 ? null : jeeps,
                  foundDeviceLocation: (LatLng newDeviceLocation) {
                    setState(() {
                      deviceLoc = newDeviceLocation;
                    });
                  },
                  currentUserFirestore: currentUserFirestore,
                  mapLoaded: (bool isLoaded) => setState(() {
                    mapLoaded = isLoaded;
                  }),
                ),
                if (!Responsive.isDesktop(context)) const Header(),
                if (Responsive.isMobile(context) && mobileTutorial)
                  Positioned(
                      bottom: 220,
                      child: PointerInterceptor(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                                width: MediaQuery.of(context).size.width,
                                padding: const EdgeInsets.all(
                                    Constants.defaultPadding),
                                decoration: const BoxDecoration(
                                  color: Constants.bgColor,
                                ),
                                child: const Column(
                                  children: [
                                    SizedBox(
                                      height: 100,
                                      child: SingleChildScrollView(
                                          physics:
                                              AlwaysScrollableScrollPhysics(),
                                          child: LiveTestInstructions()),
                                    ),
                                  ],
                                )),
                            Positioned(
                              bottom: 115,
                              right: 0,
                              child: IconButton(
                                  iconSize: 30,
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => setState(() {
                                        mobileTutorial = false;
                                      }),
                                  icon: const Icon(
                                    Icons.cancel,
                                    color: Colors.red,
                                  )),
                            )
                          ],
                        ),
                      ))
              ]),
            )
          ],
        ),
      ),
    );
  }
}
