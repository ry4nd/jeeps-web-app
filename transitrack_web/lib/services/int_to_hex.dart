// Auxiliary Function to easily convert into to hex strings since some Mapbox functions take in hex strings instead of int values

String intToHexColor(int colorValue) {
  String hexColor = colorValue.toRadixString(16).toUpperCase();
  // Take only the leftmost 6 hex digits
  hexColor = hexColor.substring(2, 8);
  // Pad the hex color value with zeros if necessary
  while (hexColor.length < 6) {
    hexColor = '0$hexColor';
  }
  return '#$hexColor';
}
