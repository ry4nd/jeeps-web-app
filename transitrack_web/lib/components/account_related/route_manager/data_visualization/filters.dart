import 'package:flutter/material.dart';
import 'package:transitrack_web/components/button.dart';
import 'package:transitrack_web/models/filter_model.dart';
import 'package:transitrack_web/models/route_model.dart';
import 'package:transitrack_web/style/constants.dart';
import 'package:transitrack_web/style/style.dart';

// Used primarily in the feedbacks and routes filter

class Filters extends StatefulWidget {
  final RouteData route;
  final List<FilterName> dropdownList;
  final FilterParameters oldFilter;
  final ValueChanged<FilterParameters> newFilter;
  const Filters(
      {super.key,
      required this.route,
      required this.dropdownList,
      required this.oldFilter,
      required this.newFilter});

  @override
  State<Filters> createState() => FiltersState();
}

class FiltersState extends State<Filters> {
  FilterName? orderBy;

  bool isDescending = false;

  @override
  void initState() {
    super.initState();

    setState(() {
      orderBy = FilterName(
          filterName: widget.dropdownList
              .firstWhere((element) =>
                  element.filterQueryName == widget.oldFilter.filterSearch)
              .filterName,
          filterQueryName: widget.oldFilter.filterSearch);
      isDescending = widget.oldFilter.filterDescending;
    });
  }

  void toggleFilter(int index) {}

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
          left: Constants.defaultPadding,
          right: Constants.defaultPadding,
          bottom: Constants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Row(
            children: [
              PrimaryText(
                text: "Advanced Search",
                color: Colors.white,
                size: 40,
                fontWeight: FontWeight.w700,
              )
            ],
          ),
          const Divider(color: Colors.white),
          const SizedBox(height: Constants.defaultPadding),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Sort By",
                style: TextStyle(color: Colors.white),
              ),
              Text(
                isDescending ? "Descending" : "Ascending",
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DropdownButton<String>(
                focusColor: Colors.transparent,
                value: orderBy!.filterName,
                onChanged: (String? newValue) {
                  setState(() {
                    orderBy = FilterName(
                        filterName: newValue!,
                        filterQueryName: widget.dropdownList
                            .firstWhere(
                                (element) => element.filterName == newValue)
                            .filterQueryName);
                  });
                },
                items: widget.dropdownList
                    .map<DropdownMenuItem<String>>((FilterName value) {
                  return DropdownMenuItem<String>(
                    value: value.filterName,
                    child: Text(value.filterName),
                  );
                }).toList(),
                hint: const Text('Order By'), // Optional
              ),
              IconButton(
                  onPressed: () => setState(() {
                        isDescending = !isDescending;
                      }),
                  icon: !isDescending
                      ? Transform(
                          transform: Matrix4.rotationX(
                              3.14159), // Rotate around the X axis by pi radians (180 degrees)
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.sort,
                          ),
                        )
                      : const Icon(Icons.sort))
            ],
          ),
          const SizedBox(height: Constants.defaultPadding),
          Button(
              onTap: () {
                widget.newFilter(FilterParameters(
                    filterSearch: orderBy!.filterQueryName,
                    filterDescending: isDescending));
                Navigator.pop(context);
              },
              text: "Search",
              color: Color(widget.route.routeColor))
        ],
      ),
    );
  }
}
