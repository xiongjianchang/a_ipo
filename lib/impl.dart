///
/// @author: 熊建昌
/// Describe:
///
import 'package:flutter/material.dart';

class EasyWebViewImpl {
  final String src;
  final num width, height;
  final bool webAllowFullScreen;
  final bool isMarkdown;
  final bool isHtml;
  final bool convertToWidgets;
  final Map<String, String> headers;
  final bool widgetsTextSelectable;
  final VoidCallback onLoaded;

  const EasyWebViewImpl({
    Key key,
    @required this.src,
    @required this.onLoaded,
    this.width,
    this.height,
    this.webAllowFullScreen = true,
    this.isHtml = false,
    this.isMarkdown = false,
    this.convertToWidgets = false,
    this.widgetsTextSelectable = false,
    this.headers = const {},
  }) : assert((isHtml && isMarkdown) == false);

  static String wrapHtml(String src) {
    if (EasyWebViewImpl.isValidHtml(src)) {
      return """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Document</title>
</head>
<body>
$src
</body>
</html>
  """;
    }
    return src;
  }

  static bool isUrl(String src) =>
      src.startsWith('https://') || src.startsWith('http://');

  static bool isValidHtml(String src) =>
      src.contains('<html>') && src.contains("</html>");
}
