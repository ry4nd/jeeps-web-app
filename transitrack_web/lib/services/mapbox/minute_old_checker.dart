bool minuteOldChecker(DateTime timestamp) {
  // Get the current time
  DateTime now = DateTime.now();

  // Calculate the difference in milliseconds
  int differenceInMilliseconds = now.difference(timestamp).inMilliseconds;

  // Check if the difference is less than a minute (60,000 milliseconds)
  return differenceInMilliseconds < 60000;
}
