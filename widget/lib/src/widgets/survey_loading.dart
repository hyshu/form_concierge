import 'package:flutter/material.dart';

class SurveyLoading extends StatelessWidget {
  const SurveyLoading({super.key, this.builder});

  final WidgetBuilder? builder;

  @override
  Widget build(context) {
    if (builder != null) return builder!(context);

    return const Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(top: 48),
        child: CircularProgressIndicator(),
      ),
    );
  }
}
