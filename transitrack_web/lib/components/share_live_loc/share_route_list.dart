// ignore_for_file: non_constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:transitrack_web/components/share_live_loc/share_route_list_tile.dart';
import 'package:transitrack_web/models/account_model.dart';
// import 'package:transitrack_web/style/constants.dart';
import '../../models/route_model.dart';

// Widget containing all active routes

class ShareRouteList extends StatefulWidget {
  final List<RouteData>? routes;
  final int routeChoice;
  final AccountData? user;
  // final ValueChanged<int> newRouteChoice;
  final Function() hoverToggle;
  const ShareRouteList(
      {super.key,
      required this.routeChoice,
      required this.routes,
      required this.user,
      // required this.newRouteChoice,
      required this.hoverToggle});

  @override
  State<ShareRouteList> createState() => _ShareRouteListState();
}

class _ShareRouteListState extends State<ShareRouteList> {
  int hover = -1;

  @override
  void initState() {
    super.initState();

    if (widget.user != null) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.routes != null)
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: widget.routes!.length,
            itemBuilder: (context, index) {
              if ((widget.routes![index].enabled) ||
                  (widget.user != null &&
                      widget.user!.account_type == 2 &&
                      widget.user!.is_verified &&
                      widget.user!.route_id == index)) {
                return MouseRegion(
                  onExit: (_) => setState(() {
                    hover = -1;
                  }),
                  onHover: (_) => setState(() {
                    hover = index;
                  }),
                  child: GestureDetector(
                    onTap: () {
                      // widget.newRouteChoice(index);
                    },
                    child: ShareRouteListTile(
                      route: widget.routes![index],
                      isSelected: widget.routeChoice == index || hover == index,
                      hoverToggle: widget.hoverToggle,
                    ),
                  ),
                );
              } else {
                return const SizedBox();
              }
            },
          ),
      ],
    );
  }
}
