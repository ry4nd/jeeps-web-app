import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:transitrack_web/components/account_related/route_manager/data_visualization/filters.dart';
import 'package:transitrack_web/components/left_drawer/logo.dart';
import 'package:transitrack_web/models/account_model.dart';
import 'package:transitrack_web/models/feedback_model.dart';
import 'package:transitrack_web/models/filter_model.dart';
import 'package:transitrack_web/models/route_model.dart';
import 'package:transitrack_web/style/constants.dart';

// This widget is called when route manager opens the feedback tab in the data visualization panel

class FeedbacksTable extends StatefulWidget {
  final RouteData route;
  const FeedbacksTable({super.key, required this.route});

  @override
  State<FeedbacksTable> createState() => _FeedbacksTableState();
}

class _FeedbacksTableState extends State<FeedbacksTable> {
  TextEditingController searchController = TextEditingController();

  int selected = -1;
  late FeedbackData? selectedFeedback;

  List<FeedbackData>? feedbacks;

  String searchString = "";

  FilterParameters orderBy =
      FilterParameters(filterSearch: "timestamp", filterDescending: true);

  @override
  void initState() {
    super.initState();

    loadFeedbacks();
  }

  void select(int index, FeedbackData? feedback) {
    setState(() {
      selected = index;
      selectedFeedback = feedback;
    });
  }

  Future<void> loadFeedbacks() async {
    setState(() {
      feedbacks = null;
    });
    select(-1, null);

    Query<Map<String, dynamic>> query = await FirebaseFirestore.instance
        .collection('feedbacks')
        .where('feedback_route', isEqualTo: widget.route.routeId);

    query = query.orderBy(orderBy.filterSearch,
        descending: orderBy.filterDescending);

    QuerySnapshot querySnapshot = await query.limit(50).get();

    setState(() {
      feedbacks = querySnapshot.docs.map((DocumentSnapshot document) {
        return FeedbackData.fromFirestore(document);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(left: Constants.defaultPadding),
        child: Row(
          children: [
            SizedBox(
              height: 700,
              width: 500,
              child: Column(
                children: [
                  SearchBar(
                    controller: searchController,
                    overlayColor: WidgetStateProperty.all(
                        Colors.white.withValues(alpha: 0.2)),
                    elevation: WidgetStateProperty.all(0.0),
                    onChanged: (String value) {
                      setState(() {
                        searchString = value;
                      });
                      select(-1, null);
                    },
                    hintText: 'Search feedback message',
                    hintStyle: WidgetStateProperty.all(
                        TextStyle(color: Color(widget.route.routeColor))),
                    leading: const Icon(Icons.search),
                    shape:
                        WidgetStateProperty.all(const ContinuousRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    )),
                    trailing: <Widget>[
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              setState(() {
                                feedbacks = null;
                              });
                              loadFeedbacks();
                            },
                            icon: const Icon(Icons.refresh),
                          ),
                          IconButton(
                            onPressed: () => AwesomeDialog(
                              dialogType: DialogType.noHeader,
                              context: (context),
                              width: 500,
                              body: PointerInterceptor(
                                  child: Filters(
                                route: widget.route,
                                dropdownList: FilterParameters.feedbacksOrderBy,
                                oldFilter: orderBy,
                                newFilter: (FilterParameters newFilter) {
                                  setState(() {
                                    orderBy = newFilter;
                                  });
                                  loadFeedbacks();
                                },
                              )),
                            ).show(),
                            icon: const Icon(Icons.filter_list),
                          )
                        ],
                      )
                    ],
                  ),
                  if (feedbacks == null)
                    SizedBox(
                        height: 500,
                        child: Center(
                            child: CircularProgressIndicator(
                          color: Color(widget.route.routeColor),
                        ))),
                  if (feedbacks != null)
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: feedbacks!.length,
                          itemBuilder: (context, index) {
                            FeedbackData feedback = feedbacks![index];

                            if (searchString.isNotEmpty &&
                                !feedback.feedback_content
                                    .toLowerCase()
                                    .contains(searchString.toLowerCase())) {
                              return const SizedBox();
                            }

                            Widget trailingWidget = setTrailingWidget(
                                orderBy.filterSearch, feedback, widget.route);

                            return ListTile(
                              onTap: () async {
                                if (selected == index) {
                                  select(-1, null);
                                } else {
                                  select(index, feedback);
                                }
                              },
                              selected: index == selected,
                              selectedColor: Colors.white,
                              selectedTileColor: Color(widget.route.routeColor)
                                  .withValues(alpha: 0.1),
                              hoverColor: Colors.white.withValues(alpha: 0.2),
                              trailing: trailingWidget,
                              title: Text(
                                '"${feedback.feedback_content}"',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontStyle: FontStyle.italic),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: Constants.defaultPadding),
            Expanded(
                child: selectedFeedback != null
                    ? FutureBuilder(
                        future: AccountData.loadAccountPairDetails(
                            selectedFeedback!.feedback_sender,
                            selectedFeedback!.feedback_recepient),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                              child: CircularProgressIndicator(
                                  color: Color(widget.route.routeColor)),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Error: ${snapshot.error}'),
                            );
                          }

                          if (!snapshot.hasData || snapshot.data == null) {
                            return const Center(
                              child:
                                  Text('Feedback Details cannot be recovered.'),
                            );
                          }

                          UsersAdditionalInfo feedbackAdditionalInfo =
                              snapshot.data!;

                          return SizedBox(
                            height: 700,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Center(
                                          child: Container(
                                            width: 34,
                                            height: 34,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(widget.route
                                                  .routeColor), // Circle color
                                            ),
                                            child: const Center(
                                              child: Icon(
                                                Icons.person,
                                                size: 22,
                                                color: Constants
                                                    .bgColor, // Icon color
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                            width: Constants.defaultPadding),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                'Feedback by ${feedbackAdditionalInfo.senderData != null ? feedbackAdditionalInfo.senderData!.account_name : "No Data"}'),
                                            Text(
                                                '<${selectedFeedback!.feedback_sender}>',
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.white
                                                        .withValues(
                                                            alpha: 0.5))),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(DateFormat('MMMM d, y').format(
                                            selectedFeedback!.timestamp
                                                .toDate())),
                                        Text(
                                            DateFormat('hh:mm a').format(
                                                selectedFeedback!.timestamp
                                                    .toDate()),
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.white
                                                    .withValues(alpha: 0.5))),
                                      ],
                                    )
                                  ],
                                ),
                                const Spacer(),
                                Center(
                                  child: Container(
                                    width: 500,
                                    padding: const EdgeInsets.all(
                                        Constants.defaultPadding * 2),
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                            width: 2,
                                            color: Colors.white
                                                .withValues(alpha: 0.5)),
                                        borderRadius: BorderRadius.circular(
                                            Constants.defaultPadding / 2)),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  const Text(
                                                    "Driver",
                                                    textAlign: TextAlign.right,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    feedbackAdditionalInfo
                                                                .recepientData !=
                                                            null
                                                        ? feedbackAdditionalInfo
                                                            .recepientData!
                                                            .account_name
                                                        : "No Data",
                                                    textAlign: TextAlign.right,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(
                                                width:
                                                    Constants.defaultPadding *
                                                        2),
                                            Expanded(
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  const Text(
                                                    "Jeepney",
                                                    textAlign: TextAlign.right,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    selectedFeedback!
                                                        .feedback_jeepney,
                                                    textAlign: TextAlign.right,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                            height:
                                                Constants.defaultPadding / 2),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children:
                                                    List.generate(5, (index) {
                                                  return Icon(
                                                    4 - index <
                                                            selectedFeedback!
                                                                .feedback_driving_rating
                                                        ? Icons.star
                                                        : Icons.star_border,
                                                    color: 4 - index <
                                                            selectedFeedback!
                                                                .feedback_driving_rating
                                                        ? Color(widget
                                                            .route.routeColor)
                                                        : Colors.grey,
                                                    size: 20,
                                                  );
                                                }),
                                              ),
                                            ),
                                            const SizedBox(
                                                width:
                                                    Constants.defaultPadding *
                                                        2),
                                            Expanded(
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children:
                                                    List.generate(5, (index) {
                                                  return Icon(
                                                    4 - index <
                                                            selectedFeedback!
                                                                .feedback_jeepney_rating
                                                        ? Icons.star
                                                        : Icons.star_border,
                                                    color: 4 - index <
                                                            selectedFeedback!
                                                                .feedback_jeepney_rating
                                                        ? Color(widget
                                                            .route.routeColor)
                                                        : Colors.grey,
                                                    size: 20,
                                                  );
                                                }),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                            height:
                                                Constants.defaultPadding / 2),
                                        const Divider(color: Colors.white),
                                        const SizedBox(
                                            height: Constants.defaultPadding),
                                        RichText(
                                            textAlign: TextAlign.center,
                                            text: TextSpan(
                                              children: [
                                                TextSpan(
                                                    text: selectedFeedback!
                                                        .feedback_content,
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontStyle:
                                                            FontStyle.italic,
                                                        fontWeight:
                                                            FontWeight.w200)),
                                              ],
                                            )),
                                        if (selectedFeedback!.feedback_img !=
                                                null &&
                                            selectedFeedback!
                                                .feedback_img!.isNotEmpty)
                                          Column(
                                            children: [
                                              const SizedBox(
                                                  height:
                                                      Constants.defaultPadding),
                                              SizedBox(
                                                  height: 200,
                                                  child: Image.network(
                                                    selectedFeedback!
                                                        .feedback_img!,
                                                    fit: BoxFit.contain,
                                                    errorBuilder:
                                                        (BuildContext context,
                                                            Object error,
                                                            StackTrace?
                                                                stackTrace) {
                                                      return const Text(
                                                        'Failed to load image',
                                                        style: TextStyle(
                                                            color: Colors.red),
                                                      );
                                                    },
                                                  )),
                                            ],
                                          )
                                      ],
                                    ),
                                  ),
                                ),
                                const Spacer(),
                              ],
                            ),
                          );
                        })
                    : const SizedBox(
                        height: 700,
                        child: Center(
                          child: Logo(),
                        )))
          ],
        ));
  }

  Widget setTrailingWidget(
      String argument, FeedbackData feedbackData, RouteData route) {
    switch (argument) {
      case 'timestamp':
        return Text(
          DateFormat('MMM d').format(feedbackData.timestamp.toDate()),
          style: const TextStyle(fontSize: 13),
        );
      case 'feedback_driving_rating':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  4 - index < feedbackData.feedback_driving_rating
                      ? Icons.star
                      : Icons.star_border,
                  color: 4 - index < feedbackData.feedback_driving_rating
                      ? Color(widget.route.routeColor)
                      : Colors.grey,
                  size: 15,
                );
              }),
            ),
          ],
        );
      case 'feedback_recepient':
        return Text(
          feedbackData.feedback_recepient,
          style: const TextStyle(fontSize: 13),
        );
      case 'feedback_jeepney_rating':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  4 - index < feedbackData.feedback_jeepney_rating
                      ? Icons.star
                      : Icons.star_border,
                  color: 4 - index < feedbackData.feedback_jeepney_rating
                      ? Color(widget.route.routeColor)
                      : Colors.grey,
                  size: 15,
                );
              }),
            ),
          ],
        );
      case 'feedback_jeepney':
        return Text(
          feedbackData.feedback_jeepney,
          style: const TextStyle(fontSize: 13),
        );
      case 'feedback_sender':
        return Text(
          feedbackData.feedback_sender,
          style: const TextStyle(fontSize: 13),
        );
      default:
        return const SizedBox();
    }
  }
}
