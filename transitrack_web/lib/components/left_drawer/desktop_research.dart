import 'package:flutter/material.dart';
import 'package:transitrack_web/components/left_drawer/live_test_instructions_desktop.dart';
import 'package:transitrack_web/style/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class DesktopResearch extends StatefulWidget {
  const DesktopResearch({super.key});

  @override
  State<DesktopResearch> createState() => _DesktopResearchState();
}

class _DesktopResearchState extends State<DesktopResearch> {
  List<Widget> pages = [];
  int page = 0;

  @override
  void initState() {
    super.initState();

    setState(() {
      pages = [
        Column(
          children: [
            const Text(
                "We are studying the effectiveness of JeePS in improving the commute experience in UP Diliman."),
            const SizedBox(
              height: Constants.defaultPadding,
            ),
            const Text(
                "5 random respondents will be rewarded 200 pesos! To qualify, make sure you fill up the pretest and post test forms with your email."),
            const Divider(color: Colors.white),
            Column(
              children: [
                const Text("Step 1: Fill out our pretest survey "),
                GestureDetector(
                  onTap: () {
                    _launchURL("https://forms.gle/QbrdVAWe3HuMrKwP7");
                  },
                  child: const Text(
                    'here!',
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(
          height: 500,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                Text("Step 2: Explore the JeePS app!"),
                SizedBox(
                  height: Constants.defaultPadding,
                ),
                Text(
                    "Follow the instructions down below.\n\nCreate a commuter account, have it verified, log in, and make sure location tracking is enabled!"),
                Divider(color: Colors.white),
                LiveTestInstructionsDesktop()
              ],
            ),
          ),
        ),
        Column(
          children: [
            const Text(
                "Great! You have experienced the features intended for the commuters."),
            const SizedBox(
              height: Constants.defaultPadding,
            ),
            const Text("Please use the same email for this step."),
            const Divider(color: Colors.white),
            Column(
              children: [
                const Text("Step 3: Fill out our post test survey "),
                GestureDetector(
                  onTap: () {
                    _launchURL("https://forms.gle/B8oFDn7DYUfAxDoL8");
                  },
                  child: const Text(
                    'here!',
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ];
    });
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        pages[page],
        const SizedBox(height: Constants.defaultPadding),
        Row(
          children: [
            Expanded(
              child: IconButton(
                  onPressed: () {
                    if (page > 0) {
                      setState(() {
                        page--;
                      });
                    }
                  },
                  icon: Icon(Icons.arrow_back)),
            ),
            Expanded(
              child: IconButton(
                  onPressed: () {
                    if (page < pages.length - 1) {
                      setState(() {
                        page++;
                      });
                    }
                  },
                  icon: Icon(Icons.arrow_forward)),
            )
          ],
        )
      ],
    );
  }
}
