import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:shimmer/shimmer.dart';
import 'package:transitrack_web/components/left_drawer/mobile_research.dart';
import 'package:transitrack_web/style/constants.dart';

class MobileResearchPrompt extends StatelessWidget {
  final Function pin;
  const MobileResearchPrompt({super.key, required this.pin});

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
          child: const Text("Join our Survey"),
        ),
        GestureDetector(
          onTap: () => AwesomeDialog(
                  context: context,
                  dialogType: DialogType.noHeader,
                  body: PointerInterceptor(child: MobileResearch(pin: pin)))
              .show(),
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
              child: const Text("Join our Survey"),
            ),
          ),
        ),
      ],
    );
  }
}
