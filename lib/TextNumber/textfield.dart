import 'package:flutter/cupertino.dart';

class SplitTextWidget extends StatelessWidget {
  final String text;
  final int maxCharactersPerLine;
  final TextStyle style;

  SplitTextWidget({
    required this.text,
    required this.maxCharactersPerLine,
    required this.style,
  });

  List<String> _splitText() {
    List<String> lines = [];
    String line = '';
    int count = 0;

    for (int i = 0; i < text.length; i++) {
      if (text[i] == ' ') {
        // If space is encountered, check if current line exceeds maxCharactersPerLine
        if (count + line.length <= maxCharactersPerLine) {
          line += text[i];
          count += 1;
        } else {
          lines.add(line);
          line = '';
          count = 0;
        }
      } else {
        line += text[i];
        count += 1;
      }
    }

    // Add the last line
    if (line.isNotEmpty) {
      lines.add(line);
    }

    return lines;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _splitText().map((line) {
        return Text(
          line,
          style: style,
        );
      }).toList(),
    );
  }
}