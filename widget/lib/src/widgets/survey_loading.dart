import 'package:flutter/material.dart';

/// Displays a loading indicator while survey data is being fetched.
class SurveyLoading extends StatelessWidget {
  /// Creates SurveyLoading with the supplied values.
  const SurveyLoading({super.key, this.builder});

  /// An optional builder that replaces the default loading indicator.
  final WidgetBuilder? builder;

  /// Builds the widget tree for the current input and state.
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
