// The account deletion page the Play Store listing links to.
//
// It does not sign in and delete by itself: the backend refuses a sign-in from
// a second device while the phone's session is live, so a web sign-in would
// fail for exactly the students still using the app. Instead it gives the
// in-app steps, and for anyone without the app, a request that goes to
// support by email.
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const appName = "Dr. SKM's Academy";
const supportEmail = 'erp.shahisolutions@gmail.com';
const background = Color(0xFFEFF4E2);
const brand = Color(0xFF87986B);
const danger = Color(0xFFD65745);

void main() => runApp(const MaterialApp(
      title: 'Delete your account – $appName',
      debugShowCheckedModeBanner: false,
      home: DeleteAccountPage(),
    ));

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _reason = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_form.currentState!.validate()) return;
    final uri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      query: _query({
        'subject': 'Account deletion request – $appName',
        'body': 'Please delete my $appName account and its data.\n\n'
            'Google account email: ${_email.text.trim()}\n'
            'Reason (optional): ${_reason.text.trim()}\n',
      }),
    );
    if (!await launchUrl(uri) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No email app found. Write to $supportEmail.')));
    }
  }

  // Uri's queryParameters encodes spaces as '+', which mail apps show as is.
  static String _query(Map<String, String> params) => params.entries
      .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
      .join('&');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                const Text(appName,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: brand)),
                const SizedBox(height: 6),
                const Text('Delete your account',
                    style:
                        TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                const SizedBox(height: 20),
                const _Card(
                  title: 'In the app (immediate)',
                  children: [
                    _Step('1', 'Open $appName and sign in.'),
                    _Step('2', 'Tap the menu icon at the top left.'),
                    _Step('3', 'Open Settings.'),
                    _Step('4', 'Under Account, tap Delete account and confirm.'),
                  ],
                ),
                const SizedBox(height: 16),
                _Card(
                  title: "Don't have the app? Request it here",
                  children: [
                    const Text(
                      'Enter the Google account you signed in with. We delete '
                      'the account within 7 days and reply to confirm.',
                      style: TextStyle(height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    Form(
                      key: _form,
                      child: Column(children: [
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                              labelText: 'Google account email',
                              border: OutlineInputBorder()),
                          validator: (v) =>
                              RegExp(r'^\S+@\S+\.\S+$').hasMatch(v?.trim() ?? '')
                                  ? null
                                  : 'Enter a valid email',
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _reason,
                          maxLines: 3,
                          decoration: const InputDecoration(
                              labelText: 'Reason (optional)',
                              border: OutlineInputBorder()),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: danger),
                        onPressed: _send,
                        child: const Text('Request account deletion',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const SelectableText(
                        'Or email $supportEmail from that address.',
                        style: TextStyle(fontSize: 13, color: Colors.black54)),
                  ],
                ),
                const SizedBox(height: 16),
                const _Card(
                  title: 'What is deleted',
                  children: [
                    Text(
                      'Everything tied to the account: your profile (name, '
                      'email, phone, photo), course selection, subscription, '
                      'progress, quiz and test results, saved items, '
                      'comments, notification tokens and sessions. Nothing '
                      'is kept, and deletion cannot be undone.',
                      style: TextStyle(height: 1.5),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Card({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      );
}

class _Step extends StatelessWidget {
  final String number;
  final String text;

  const _Step(this.number, this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(
              radius: 12,
              backgroundColor: brand,
              child: Text(number,
                  style: const TextStyle(fontSize: 12, color: Colors.white))),
          const SizedBox(width: 10),
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.only(top: 2), child: Text(text))),
        ]),
      );
}
