import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:transitrack_web/style/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class MobileResearchPrompt extends StatelessWidget {
  const MobileResearchPrompt({super.key});

  Future<void> _launchSurveyUrl() async {
    final Uri url = Uri.parse(
        'https://docs.google.com/forms/d/e/1FAIpQLSe7py3kWqHirKDr62h5bdLg4ae2qnXZbzkL3kJjf-BnUFtvog/viewform?usp=dialog');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(Constants.defaultPadding),
          margin:
              const EdgeInsets.symmetric(horizontal: Constants.defaultPadding),
          decoration: BoxDecoration(
            border: Border.all(width: 2, color: Colors.white),
            borderRadius: const BorderRadius.all(
                Radius.circular(Constants.defaultPadding)),
          ),
          child: const Text("Answer Survey"),
        ),
        GestureDetector(
          onTap: _launchSurveyUrl,
          child: Shimmer.fromColors(
            baseColor: Colors.transparent,
            highlightColor: Colors.white.withValues(alpha: 0.5),
            period: const Duration(seconds: 5),
            child: Container(
              width: double.maxFinite,
              padding: const EdgeInsets.all(Constants.defaultPadding),
              margin: const EdgeInsets.symmetric(
                  horizontal: Constants.defaultPadding),
              decoration: BoxDecoration(
                color: Constants.bgColor,
                border: Border.all(width: 2, color: Colors.white),
                borderRadius: const BorderRadius.all(
                    Radius.circular(Constants.defaultPadding)),
              ),
              child: const Text("Answer Survey"),
            ),
          ),
        ),
      ],
    );
  }
}
