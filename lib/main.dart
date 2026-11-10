// The account deletion page the Play Store listing links to.
//
// A student with a password signs in here and the account is deleted on the
// spot: POST /auth/login, then DELETE /users/me with that token. Signing in
// here signs the phone out, which does not matter since the account is about
// to go. A Google or Apple account has no password, so it can still send a
// request to support by email.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

const appName = "Dr. SKM's Academy";
const supportEmail = 'contact@drskmacademy.com';
const background = Color(0xFFEFF4E2);
const brand = Color(0xFF87986B);
const danger = Color(0xFFD65745);
const api = 'https://doctorapp-backend-cl2h.onrender.com/api';

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
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;
  bool _deleted = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (!_form.currentState!.validate()) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete your account?'),
        content: const Text(
            'Your account and all its data are deleted right away. This cannot '
            'be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              style: TextButton.styleFrom(foregroundColor: danger),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final login = await http.post(
        Uri.parse('$api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _email.text.trim(),
          'password': _password.text,
          'deviceId': 'web-delete-page',
        }),
      );
      if (login.statusCode != 200) {
        throw _message(login, 'Could not sign in. Check your email and password.');
      }
      final token = jsonDecode(login.body)['accessToken'];
      final del = await http.delete(Uri.parse('$api/users/me'),
          headers: {'Authorization': 'Bearer $token'});
      if (del.statusCode != 200) {
        throw _message(del, 'Failed to delete the account. Please try again.');
      }
      // The tokens die with the account, so there is nothing to sign out of.
      setState(() => _deleted = true);
    } on String catch (e) {
      setState(() => _error = e);
    } catch (_) {
      setState(() => _error =
          'Could not reach the server. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // Errors look like { "error": { "code", "message", "status" } }.
  static String _message(http.Response r, String fallback) {
    try {
      return jsonDecode(r.body)['error']['message']?.toString() ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  Future<void> _requestByEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      query: _query({
        'subject': 'Account deletion request – $appName',
        'body': 'Please delete my $appName account and its data.\n\n'
            'Account email: ${_email.text.trim()}\n',
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
                  title: "Don't have the app? Delete it here",
                  children: _deleted
                      ? const [
                          Text(
                            'Your account has been deleted. You have been '
                            'signed out on every device.',
                            style: TextStyle(height: 1.4),
                          ),
                        ]
                      : [
                          const Text(
                            'Sign in with the email and password of your '
                            'account. It is deleted immediately.',
                            style: TextStyle(height: 1.4),
                          ),
                          const SizedBox(height: 16),
                          Form(
                            key: _form,
                            child: AutofillGroup(
                              child: Column(children: [
                                TextFormField(
                                  controller: _email,
                                  keyboardType: TextInputType.emailAddress,
                                  autofillHints: const [AutofillHints.email],
                                  decoration: const InputDecoration(
                                      labelText: 'Email',
                                      border: OutlineInputBorder()),
                                  validator: (v) => RegExp(r'^\S+@\S+\.\S+$')
                                          .hasMatch(v?.trim() ?? '')
                                      ? null
                                      : 'Enter a valid email',
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _password,
                                  obscureText: true,
                                  autofillHints: const [AutofillHints.password],
                                  onFieldSubmitted: (_) =>
                                      _busy ? null : _delete(),
                                  decoration: const InputDecoration(
                                      labelText: 'Password',
                                      border: OutlineInputBorder()),
                                  validator: (v) => (v ?? '').isEmpty
                                      ? 'Enter your password'
                                      : null,
                                ),
                              ]),
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(_error!,
                                style: const TextStyle(color: danger)),
                          ],
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                  backgroundColor: danger),
                              onPressed: _busy ? null : _delete,
                              child: _busy
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white))
                                  : const Text('Delete my account',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                  'Signed up with Google or Apple? ',
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.black54)),
                              TextButton(
                                onPressed: _requestByEmail,
                                child: const Text(
                                    'Request deletion by email',
                                    style: TextStyle(fontSize: 13)),
                              ),
                            ],
                          ),
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
                      'from the account is kept. Deletion cannot be undone.',
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
