import 'package:flutter/material.dart';

class SurveyLoading extends StatelessWidget {
  const SurveyLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
