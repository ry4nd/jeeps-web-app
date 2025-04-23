// Auxiliary Model for Filtering results

class FilterParameters {
  String filterSearch;
  bool filterDescending;
  DateTime? filterStart;
  DateTime? filterEnd;

  FilterParameters({
    required this.filterSearch,
    required this.filterDescending,
    this.filterStart,
    this.filterEnd,
  });

  setFilterSearch(String value) {
    filterSearch = value;
  }

  setFilterDescending(bool value) {
    filterDescending = value;
  }

  setFilterStart(DateTime? value) {
    filterStart = value;
  }

  setFilterEnd(DateTime? value) {
    filterEnd = value;
  }

  static List<FilterName> feedbacksOrderBy = [
    FilterName(filterName: "Date", filterQueryName: "timestamp"),
    FilterName(
        filterName: "Driver Rating",
        filterQueryName: "feedback_driving_rating"),
    FilterName(
        filterName: 'Driver Email', filterQueryName: "feedback_recepient"),
    FilterName(
        filterName: 'Jeepney Rating',
        filterQueryName: "feedback_jeepney_rating"),
    FilterName(
        filterName: 'Jeepney Plate Number',
        filterQueryName: "feedback_jeepney"),
    FilterName(
        filterName: 'Feedback Provider Email',
        filterQueryName: "feedback_sender"),
  ];

  static List<FilterName> driversOrderBy = [
    FilterName(filterName: "Name", filterQueryName: "account_name"),
    FilterName(filterName: "Email", filterQueryName: "account_email"),
    FilterName(filterName: 'Verified Status', filterQueryName: "is_verified"),
    FilterName(
        filterName: 'PUV Plate Number (Driving)',
        filterQueryName: "jeep_driving"),
  ];

  static List<FilterName> commutersOrderBy = [
    FilterName(filterName: "Name", filterQueryName: "account_name"),
    FilterName(filterName: "Email", filterQueryName: "account_email"),
    FilterName(filterName: "Status", filterQueryName: "account_banned"),
  ];

  static List<FilterName> reportsOrderBy = [
    FilterName(filterName: "Date", filterQueryName: "timestamp"),
    FilterName(
        filterName: 'Reported Jeepney', filterQueryName: "report_jeepney"),
    FilterName(
        filterName: 'Reported Driver', filterQueryName: "report_recepient"),
    FilterName(filterName: 'Report Issuer', filterQueryName: "report_sender")
  ];
}

class FilterName {
  String filterName;
  String filterQueryName;

  FilterName({required this.filterName, required this.filterQueryName});

  setFilterName(String value) {
    filterName = value;
  }

  setFilterQueryName(String value) {
    filterQueryName = value;
  }
}
