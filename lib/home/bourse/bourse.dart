import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class Bourse extends StatefulWidget {
  const Bourse({Key? key}) : super(key: key);

  @override
  _BourseState createState() => _BourseState();
}

class _BourseState extends State<Bourse> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  _launchURL(url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

 _sendMessage() async {
  final smtpServer = gmail('sgovs.af@gmail.com', 'gtkt kmkg sqqj bdkl');

  final message = Message()
    ..from = const Address('sgovs.af@gmail.com', 'SGOVS')
    ..recipients.add(_emailController.text)
    ..subject = 'New Message from your App'
    ..text = _messageController.text;

  try {
    final sendReport = await send(message, smtpServer);
    print('Message sent: ' + sendReport.toString());
    _showSnackBar(context, 'Message sent successfully', Colors.green);
    _emailController.clear();
    _messageController.clear();
  } on MailerException catch (e) {
    print('Message not sent.');
    for (var p in e.problems) {
      print('Problem: ${p.code}: ${p.msg}');
    }
    _showSnackBar(context, 'Message not sent. Please try again.', Colors.red);
  }
}


  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(),
      body: Container(
        decoration: const BoxDecoration(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () {
                    _launchURL('https://www.sgbv.dz/');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    width: 300,
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(28, 120, 117, 0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "SGBV Actualités",
                      style: TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _launchURL('https://www.sgbv.dz/?page=boc&lang=fr');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    width: 300,
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(28, 120, 117, 0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "consulter les bulletins de cotations",
                          style: TextStyle(
                            fontFamily: 'Sora',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      _sendMessage();
                    },
                    child: const Text('Envoyer'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
