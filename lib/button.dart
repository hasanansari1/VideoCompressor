import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ButtonWidget extends StatelessWidget
{
  final String text;
  final VoidCallback onClicked;


  ButtonWidget({
    Key? key,
    required this.text,
    required this.onClicked,
  }) : super(key: key);

  @override
  Widget build(BuildContext context)=> ElevatedButton(child: Text(text),
    onPressed: onClicked,);
}