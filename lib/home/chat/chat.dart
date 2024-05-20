import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class ChatMessage {
  final String message;
  final DateTime timestamp;
  final String senderId;
  final String receiverId;

  ChatMessage({
    required this.message,
    required this.timestamp,
    required this.senderId,
    required this.receiverId,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      senderId: json['senderId'],
      receiverId: json['receiverId'],
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ChatPage(),
    );
  }
}

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late List<ChatMessage> _chatMessages;
  late TextEditingController _messageController;
  late List<Map<String, dynamic>> _participants;
  String? _selectedParticipantId;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _chatMessages = [];
    _messageController = TextEditingController();
    _participants = [];
    _fetchParticipants(); // Fetch participants when the app starts
    _startTimer(); // Start the timer to fetch messages periodically
  }

  @override
  void dispose() {
    _timer.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      // Fetch messages every 10 seconds
      if (_selectedParticipantId != null) {
        _fetchMessagesWithParticipant(_selectedParticipantId!);
      }
    });
  }

  Future<void> _fetchParticipants() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int adminId = prefs.getInt('admin_id') ?? 0;

      final response = await http.get(
        Uri.parse(
            'http://regestrationrenion.atwebpages.com/api.php?admin_id=$adminId'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _participants = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        });
      } else {
        throw Exception('Failed to fetch participants');
      }
    } catch (e) {
      print("Error fetching participants: $e");
    }
  }

 Future<void> _fetchMessagesWithParticipant(String participantId) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int adminId = prefs.getInt('admin_id') ?? 0;

    final response = await http.get(
      Uri.parse('http://regestrationrenion.atwebpages.com/api4.php?action=fetch_messages&admin_id=$adminId&participant_id=$participantId'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        _chatMessages = data.map((e) => ChatMessage.fromJson(e)).toList();
      });
    } else {
      throw Exception('Failed to load messages');
    }
  } catch (e) {
    print("Error fetching messages: $e");
  }
}


  Future<void> _sendMessage(String message, String receiverId) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int adminId = prefs.getInt('admin_id') ?? 0;

    final response = await http.post(
      Uri.parse('http://regestrationrenion.atwebpages.com/messages.php'),
      body: jsonEncode(<String, String>{
        'message': message,
        'senderId': adminId.toString(), // Use admin ID as sender ID
        'receiverId': receiverId,
      }),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    if (response.statusCode == 201) {
      _fetchMessagesWithParticipant(receiverId);
      _messageController.clear();
    } else {
      print("ssssssssssssssssssss:${response.body}");

      throw Exception('Failed to send message');
    }
  } catch (e) {
    print("Error sending message: $e");
    // Handle error here
  }
}


 @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Chat'),
    ),
    body: Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: ListView.builder(
              itemCount: _participants.length,
              itemBuilder: (context, index) {
                final participant = _participants[index];
                return InkWell(
                  onTap: () {
  setState(() {
    if (participant['id'] != null) {
      _selectedParticipantId = participant['id'];
      _fetchMessagesWithParticipant(_selectedParticipantId!);
    }
  });
},

                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey[200]!,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                         backgroundColor: Colors.blue,
                        ),
                        SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${participant['name']} ${participant['prename']}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Last message here',
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        VerticalDivider(width: 0),

        Expanded(
          flex: 4,
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _chatMessages.length,
                    reverse: true,
                    itemBuilder: (context, index) {
                      final message = _chatMessages[index];
                      final isAdminMessage = message.senderId != _selectedParticipantId;

                      return Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Align(
                          alignment: isAdminMessage ? Alignment.topRight : Alignment.topLeft,
                          child: Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isAdminMessage ? Colors.blue : Colors.grey[200],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  message.message,
                                  style: TextStyle(
                                    color: isAdminMessage ? Colors.white : Colors.black,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  message.timestamp.toString(),
                                  style: TextStyle(
                                    color: isAdminMessage ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    MaterialButton(
                      onPressed: () {
                        if (_messageController.text.isNotEmpty && _selectedParticipantId != null) {
                          _sendMessage(
                            _messageController.text,
                            _selectedParticipantId!,
                          );
                        }
                      },
                      color: Theme.of(context).primaryColor,
                      textColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text('Send'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
}