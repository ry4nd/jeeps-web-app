import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:transitrack_web/components/left_drawer/route_list_tile.dart';
import 'package:transitrack_web/models/account_model.dart';
import 'package:transitrack_web/style/constants.dart';
import '../../models/route_model.dart';

// Widget containing all active routes

class RouteList extends StatefulWidget {
  final List<RouteData>? routes;
  final int routeChoice;
  final AccountData? user;
  final ValueChanged<int> newRouteChoice;
  final Function() hoverToggle;
  const RouteList(
      {super.key,
      required this.routeChoice,
      required this.routes,
      required this.user,
      required this.newRouteChoice,
      required this.hoverToggle});

  @override
  State<RouteList> createState() => _RouteListState();
}

class _RouteListState extends State<RouteList> {
  int hover = -1;
  bool show_discounted = false;

  @override
  void initState() {
    super.initState();

    if (widget.user != null) {
      setState(() {
        show_discounted = widget.user!.show_discounted;
      });
    }
  }

  @override
  void didUpdateWidget(covariant RouteList oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.user != null &&
        widget.user!.show_discounted != show_discounted) {
      setState(() {
        show_discounted = widget.user!.show_discounted;
      });
    }
  }

  void updateBooleanField(String documentId, bool newValue) async {
    // Get a reference to the Firestore collection
    CollectionReference collectionReference =
        FirebaseFirestore.instance.collection('accounts');

    try {
      // Get a reference to the document you want to update
      DocumentReference documentReference = collectionReference.doc(documentId);

      // Update the boolean field
      await documentReference.update({'show_discounted': newValue});

      print('Boolean field updated successfully!');
    } catch (e) {
      print('Error updating boolean field: $e');
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
                      widget.newRouteChoice(index);
                    },
                    child: RouteListTile(
                        route: widget.routes![index],
                        isSelected:
                            widget.routeChoice == index || hover == index,
                        hoverToggle: widget.hoverToggle,
                        show_discounted: show_discounted),
                  ),
                );
              } else {
                return const SizedBox();
              }
            },
          ),
        if (widget.routes == null)
          const Center(child: CircularProgressIndicator()),
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: Constants.defaultPadding),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Row(
              children: [
                Text("Show discounted fare"),
                IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: null,
                    tooltip:
                        "Discounted Fare includes Student, PWD, and Senior Citizens",
                    iconSize: 15,
                    icon: Icon(Icons.question_mark))
              ],
            ),
            Switch(
              activeColor: Colors.blue,
              activeTrackColor: Colors.blue.withOpacity(0.5),
              inactiveThumbColor: Colors.grey,
              value: show_discounted,
              onChanged: (value) {
                setState(() {
                  show_discounted = value;
                });

                if (widget.user != null) {
                  updateBooleanField(widget.user!.account_id, value);
                }
              },
            ),
          ]),
        ),
      ],
    );
  }
}
