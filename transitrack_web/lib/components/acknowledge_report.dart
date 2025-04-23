import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:transitrack_web/models/report_model.dart';
import 'package:transitrack_web/style/constants.dart';
import 'package:url_launcher/url_launcher.dart';

void acknowledgeReport(BuildContext context, ReportData report,
    TextEditingController emailController, String routeName) {
  // Create a default message
  String defaultMessage = 'Dear Reporter,\n\n'
      'We have received your report regarding "${report.getReportType()}" on ${DateFormat('MMM d, y hh:mm a').format(report.timestamp.toDate())}.\n'
      'Plate Number: ${report.report_jeepney}\n'
      'Driver\'s Account: ${report.report_recepient}\n\n'
      'Thank you for bringing this to our attention. We will take the necessary actions.\n\n'
      'Best regards,\n'
      '$routeName Jeepney Operator';

  // Initialize the email controller with the default message
  emailController.text = defaultMessage;

  AwesomeDialog(
    context: context,
    dialogType: DialogType.noHeader,
    width: 1500,
    body: PointerInterceptor(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              children: [
                TextField(
                  controller: TextEditingController(text: report.report_sender),
                  decoration: InputDecoration(
                    labelText: 'Reporter Email',
                    border: OutlineInputBorder(),
                  ),
                  enabled: false, // Makes the text field uneditable
                ),
                const SizedBox(height: Constants.defaultPadding / 2),
                TextField(
                  controller: emailController,
                  maxLines: 12,
                  decoration: InputDecoration(
                    hintText: 'Message',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: Constants.defaultPadding / 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        String emailBody = emailController.text;
                        String subject =
                            '${report.getReportType()} Report Acknowledgement';
                        String body = Uri.encodeComponent(emailBody);

                        final Uri emailUri = Uri(
                          scheme: 'https',
                          host: 'mail.google.com',
                          path: '/mail/',
                          queryParameters: {
                            'view': 'cm',
                            'fs': '1',
                            'to': report.report_sender,
                            'su': subject,
                            'body': emailBody,
                          },
                        );

                        if (await canLaunchUrl(emailUri)) {
                          await launchUrl(emailUri);
                        } else {
                          throw Exception('Could not launch $emailUri');
                        }

                        Navigator.pop(context);
                      },
                      child: Text('Send'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Handle cancel action
                        Navigator.pop(context);
                      },
                      child: Text('Cancel'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    showCloseIcon: true,
    dismissOnBackKeyPress: true,
    dismissOnTouchOutside: true,
  ).show();
}
