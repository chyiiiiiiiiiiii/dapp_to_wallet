import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MyTextField extends StatelessWidget {
  final String? hint;
  final TextStyle? hintStyle;
  final int? maxLines;
  final bool autoFocus;
  final bool obscureText;
  final InputBorder? inputBorder;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? textInputFormatter;
  final TextEditingController textEditingController;
  final FocusNode? focusNode;
  final Function()? onComplete;

  const MyTextField({
    Key? key,
    this.hint,
    this.hintStyle,
    this.maxLines,
    this.autoFocus = false,
    this.obscureText = false,
    this.inputBorder,
    this.keyboardType,
    this.textInputAction = TextInputAction.done,
    this.textInputFormatter,
    required this.textEditingController,
    this.focusNode,
    this.onComplete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      style: const TextStyle(fontSize: 16.0),
      keyboardType: keyboardType,
      maxLines: maxLines,
      minLines: 1,
      autofocus: autoFocus,
      obscureText: obscureText,
      cursorColor: Colors.brown,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: hintStyle,
        border: inputBorder,
      ),
      inputFormatters: textInputFormatter,
      textInputAction: textInputAction,
      controller: textEditingController,
      focusNode: focusNode,
      onEditingComplete: onComplete,
    );
  }
}
