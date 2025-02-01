import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:transitrack_web/components/left_drawer/desktop_research.dart';
import 'package:transitrack_web/style/constants.dart';

class DesktopResearchPrompt extends StatefulWidget {
  const DesktopResearchPrompt({super.key});

  @override
  State<DesktopResearchPrompt> createState() => _DesktopResearchPromptState();
}

class _DesktopResearchPromptState extends State<DesktopResearchPrompt> {
  bool openPrompt = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (!openPrompt)
          Shimmer.fromColors(
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
              child: const Text("Join our Survey"),
            ),
          ),
        GestureDetector(
          onTap: () => setState(() {
            openPrompt = !openPrompt;
          }),
          child: Container(
            width: double.maxFinite,
            padding: const EdgeInsets.all(Constants.defaultPadding),
            margin: const EdgeInsets.symmetric(
                horizontal: Constants.defaultPadding),
            decoration: BoxDecoration(
              border: Border.all(width: 2, color: Colors.white),
              borderRadius: const BorderRadius.all(
                  Radius.circular(Constants.defaultPadding)),
            ),
            child: openPrompt
                ? const DesktopResearch()
                : const Text("Join our Survey"),
          ),
        ),
      ],
    );
  }
}
