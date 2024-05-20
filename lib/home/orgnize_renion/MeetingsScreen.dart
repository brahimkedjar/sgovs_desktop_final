import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class MeetingsScreen extends StatefulWidget {
  const MeetingsScreen({super.key});

  @override
  _MeetingsScreenState createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends State<MeetingsScreen> {
  List<Map<String, dynamic>> _meetings = [];
  List<Map<String, dynamic>> _preparationMeetings = [];
  String? _selectedMeetingType;
  late DateTime _selectedDate;
  List<Map<String, dynamic>> _enCoursMeetings = [];
  List<Map<String, dynamic>> _termineesMeetings = [];
  String? _selectedUser; // Initialize selected user variable
  String? _selectedParticipant;
  List<String> _selectedParticipants = [];
String documentConvocationValue = '';
String documentOrderJourValue = '';
DateTime _selectedDateOnly = DateTime.now();
TimeOfDay _selectedTimeOnly = TimeOfDay.now();
  @override
  void initState() {
    super.initState();
    _fetchMeetings();
    _selectedDate = DateTime.now();
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  Future<void> _deleteMeeting(int meetingId, bool isPreparation) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int adminId = prefs.getInt('admin_id') ?? 0;

      final response = await http.delete(
        Uri.parse(
            'http://regestrationrenion.atwebpages.com/delete_meetings.php'),
        body: {
          'id': meetingId.toString(),
          'admin_id': adminId.toString(),
          'is_preparation': isPreparation ? '1' : '0', // Convert bool to string
        },
      );

      if (response.statusCode == 200) {
        _fetchMeetings();
        _showSnackBar(context, 'Meeting deleted successfully', Colors.green);
      } else {
        throw Exception('Failed to delete meeting');
      }
    } catch (e) {
      print('Error deleting meeting: $e');
      // Handle error here
      _showSnackBar(context, 'Failed to delete meeting', Colors.red);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchParticipants() async {
    try {
      // Get the admin_id from shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int adminId = prefs.getInt('admin_id') ?? 0;

      final response = await http.get(
        Uri.parse(
            'http://regestrationrenion.atwebpages.com/api.php?admin_id=$adminId'),
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        // Handle error
        return [];
      }
    } catch (e) {
      _showSnackBar(context, "Error fetching participants", Colors.red);
      return [];
    }
  }

  Future<void> _fetchMeetings() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int adminId = prefs.getInt('admin_id') ?? 0;

      final response = await http.get(Uri.parse(
          'http://regestrationrenion.atwebpages.com/get_meetings.php?admin_id=$adminId'));

      if (response.statusCode == 200) {
        final List<Map<String, dynamic>> allMeetings =
            jsonDecode(response.body).cast<Map<String, dynamic>>();
        final DateTime currentDate = DateTime.now();
print("ssssssssssssssss:${currentDate.hour}");
        setState(() {
          _meetings = [];
          _enCoursMeetings = [];
          _preparationMeetings = [];
          _termineesMeetings = [];

          for (var meeting in allMeetings) {
            final DateTime meetingDate = DateTime.parse(meeting['date']+ ' ' + meeting['time']);

            if (meetingDate.isAfter(currentDate)) {
              // Check if the meeting is a preparation meeting or scheduled meeting
              if (meeting['is_preparation'] == 1) {
                _preparationMeetings.add(meeting);
              } else {
                _meetings.add(meeting);
              }
            } else if (meetingDate.year == currentDate.year &&
                meetingDate.month == currentDate.month &&
                meetingDate.day == currentDate.day &&
                meetingDate.hour == currentDate.hour &&
                meetingDate.minute == currentDate.minute 
               
             ) {
              _enCoursMeetings.add(meeting);
            }else if (meetingDate.isBefore(currentDate)) {
              _termineesMeetings.add(meeting);
            }
          }
        });
      } else {
        throw Exception('Failed to fetch meetings');
      }
    } catch (e) {
      print('Error fetching meetings: $e');
      // Handle error here
    }
  }

 Future<void> _addPreparationMeeting(String title, DateTime date, TimeOfDay time, String documentConvocation, String documentOrderJour, List<String> selectedParticipants) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int adminId = prefs.getInt('admin_id') ?? 0;

    // Combine date and time into a single DateTime object
    DateTime combinedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    final response = await http.post(
      Uri.parse('http://regestrationrenion.atwebpages.com/add_meeting.php'),
      body: {
        'title': title,
        'date': DateFormat('yyyy-MM-dd HH:mm').format(combinedDateTime), // Format date and time
        'admin_id': adminId.toString(), // Include admin_id in the request body
        'is_preparation': '1', // Indicate that this is a preparation meeting
        'document_convocations': documentConvocation, // Include DocumentConvocation
        'document_order_jours': documentOrderJour, // Include DocumentOrderJour
        'participants': selectedParticipants.join(','), // Convert list to comma-separated string
      },
    );

    if (response.statusCode == 200) {
      _fetchMeetings(); // Fetch all meetings, including preparation meetings
    } else {
      throw Exception('Failed to add preparation meeting');
    }
  } catch (e) {
    print('Error adding preparation meeting: $e');
    // Handle error here
  }
}




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meetings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildMeetingCategory(
                'Programmée',
                _meetings
                    .map<Widget>((meeting) => _buildMeetingCard(meeting))
                    .toList(),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildMeetingCategory(
                'En Préparation',
                [
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return StatefulBuilder(
                            builder:
                                (BuildContext context, StateSetter setState) {
                              return AlertDialog(
                                title: const Text(
                                    'Ajouter une réunion'),
                                content: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      DropdownButtonFormField<String>(
                                        value: _selectedMeetingType,
                                        items: const [
                                          DropdownMenuItem(
                                              value: 'Conseil d’administration',
                                              child: Text(
                                                  'Conseil d’administration')),
                                          DropdownMenuItem(
                                              value:
                                                  'Assemblée générale ordinaire',
                                              child: Text(
                                                  'Assemblée générale ordinaire')),
                                          DropdownMenuItem(
                                              value:
                                                  'Assemblée générale extraordinaire',
                                              child: Text(
                                                  'Assemblée générale extraordinaire')),
                                          DropdownMenuItem(
                                              value: 'Assemblée générale mixte',
                                              child: Text(
                                                  'Assemblée générale mixte')),
                                        ],
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedMeetingType = value;
                                          });
                                        },
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          hintText: 'Sélectionner un type',
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                     InkWell(
  onTap: () async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      final TimeOfDay? timePicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
      if (timePicked != null) {
        setState(() {
          _selectedDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            timePicked.hour,
            timePicked.minute,
          );
          // Separate date and time into two variables
          _selectedDateOnly = picked; // Date only
          _selectedTimeOnly = timePicked; // Time only
        });
      }
    }
  },
  child: Container(
    height: 50,
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey),
      borderRadius: BorderRadius.circular(5),
    ),
    alignment: Alignment.center,
    child: Text(
      'Selected Date and Time: ${DateFormat('yyyy-MM-dd HH:mm').format(_selectedDate)}',
      style: const TextStyle(fontSize: 16),
    ),
  ),
),

                                      const SizedBox(height: 10),
                                      TextField(
          // TextField for DocumentConvocation
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'DocumentConvocation',
          ),
          onChanged: (value) {
            // Update documentConvocationValue when the text changes
            setState(() {
              documentConvocationValue = value;
            });
          },
        ),
        const SizedBox(height: 10),
        TextField(
          // TextField for DocumentOrderJour
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'DocumentOrderJour',
          ),
          onChanged: (value) {
            // Update documentOrderJourValue when the text changes
            setState(() {
              documentOrderJourValue = value;
            });
          },
        ),
                                      const SizedBox(height: 10),
                                      FutureBuilder<List<Map<String, dynamic>>>(
                                        future: _fetchParticipants(),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const CircularProgressIndicator();
                                          } else if (snapshot.hasError) {
                                            return Text(
                                                'Error: ${snapshot.error}');
                                          } else if (snapshot.hasData) {
                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            30.0),
                                                    color: const Color.fromRGBO(
                                                        28, 120, 117, 0.6),
                                                  ),
                                                  margin:
                                                      const EdgeInsets.fromLTRB(
                                                          0, 20, 0, 0),
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  child: DropdownButton<String>(
                                                    underline: Container(),
                                                    isExpanded: true,
                                                    hint: const Text(
                                                      'Sélectionner les participants',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontFamily: 'Sora',
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    value: _selectedParticipant,
                                                    onChanged:
                                                        (String? newValue) {
                                                      setState(() {
                                                        _selectedParticipant =
                                                            newValue;
                                                        if (_selectedParticipants
                                                            .contains(
                                                                newValue)) {
                                                          _selectedParticipants
                                                              .remove(newValue);
                                                        } else {
                                                          _selectedParticipants
                                                              .add(newValue!);
                                                        }
                                                      });
                                                    },
                                                    items: snapshot.data!.map<
                                                            DropdownMenuItem<
                                                                String>>(
                                                        (participant) {
                                                      return DropdownMenuItem<
                                                          String>(
                                                        value:
                                                            '${participant['id']}',
                                                        child: Text(
                                                          '${participant['name']} ${participant['prename']}',
                                                        ),
                                                      );
                                                    }).toList(),
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                const Text(
                                                  'Les Participants Sélectionnés :',
                                                  style: TextStyle(
                                                    fontFamily: 'Sora',
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color.fromRGBO(
                                                        28, 120, 117, 1),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Wrap(
                                                  spacing: 8.0,
                                                  children:
                                                      _selectedParticipants
                                                          .map<Widget>(
                                                              (selectedId) {
                                                    final selectedParticipant =
                                                        snapshot.data!
                                                            .firstWhere(
                                                      (participant) =>
                                                          participant['id'] ==
                                                          selectedId,
                                                      orElse: () => {
                                                        'name': 'Unknown',
                                                        'prename': 'Participant'
                                                      },
                                                    );
                                                    return Chip(
                                                      label: Text(
                                                        '${selectedParticipant['name']} ${selectedParticipant['prename']}',
                                                      ),
                                                      onDeleted: () {
                                                        setState(() {
                                                          _selectedParticipants
                                                              .remove(
                                                                  selectedId);
                                                        });
                                                      },
                                                    );
                                                  }).toList(),
                                                ),
                                              ],
                                            );
                                          } else {
                                            return const Text(
                                                'No participants found');
                                          }
                                        },
                                      ),
                                      if (_selectedUser != null) ...[
                                        const SizedBox(height: 10),
                                        Text('Selected User: $_selectedUser'),
                                      ],
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      _addPreparationMeeting(
  _selectedMeetingType!,
  _selectedDateOnly, _selectedTimeOnly,
  documentConvocationValue,
  documentOrderJourValue,
  _selectedParticipants,
);

                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('Enregistrer'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('Annuler'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Ajouter',
                        style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 10),
                  ..._preparationMeetings
                      .map<Widget>((meeting) => _buildMeetingCard(meeting)),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildMeetingCategory(
                'En Cours',
                _enCoursMeetings
                    .map<Widget>((meeting) => _buildMeetingCard(meeting))
                    .toList(),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildMeetingCategory(
                'Terminées',
                _termineesMeetings
                    .map<Widget>((meeting) => _buildMeetingCard(meeting))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingCategory(String title, List<Widget> meetings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _getCategoryColor(title)),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.separated(
            separatorBuilder: (BuildContext context, int index) =>
                const Divider(),
            itemCount: meetings.length,
            itemBuilder: (BuildContext context, int index) {
              return meetings[index];
            },
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Programmée':
        return Colors.blue;
      case 'En Préparation':
        return Colors.green;
      case 'En Cours':
        return Colors.orange;
      case 'Terminées':
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  Widget _buildMeetingCard(Map<String, dynamic> meeting) {
    bool isPreparationMeeting =
        meeting.containsKey('admin_id'); // Check if it's a preparation meeting
    return Card(
      elevation: 4,
      child: ListTile(
        title: Text(
          meeting['title'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(meeting['date']),
            Text(
              'Time: ${meeting['time']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Location: ${meeting['location']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteMeeting(meeting['id'],
                    isPreparationMeeting); // Pass isPreparationMeeting value
              },
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
