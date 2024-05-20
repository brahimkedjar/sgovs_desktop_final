import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CreateVotePage extends StatefulWidget {
  const CreateVotePage({super.key});

  @override
  _CreateVotePageState createState() => _CreateVotePageState();
}

class _CreateVotePageState extends State<CreateVotePage> {
  final List<String> _selectedParticipants = [];
  DateTime _closingDate = DateTime.now();
  List<Map<String, dynamic>>? _participantsList;
  final List<Map<String, dynamic>> _optionsWithKeys = [];

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _newOptionController = TextEditingController();

  Future<DateTime?> _selectDateTime(BuildContext context) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (selectedDate != null) {
      final TimeOfDay? selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (selectedTime != null) {
        return DateTime(selectedDate.year, selectedDate.month, selectedDate.day,
            selectedTime.hour, selectedTime.minute);
      }
    }
    return null;
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
      _showSnackBar("Error fetching participants", context);
      return [];
    }
  }

  void _saveVote(BuildContext context) async {
    // Check if any of the required fields are null
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _optionsWithKeys.isEmpty ||
        _selectedParticipants.isEmpty ||
        _closingDate == null) {
      _showSnackBar("All fields are required", context);
      return;
    }

    // Fetch admin_id from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int adminId = prefs.getInt('admin_id') ?? 0;

    Map<String, dynamic> voteData = {
      'title': _titleController.text,
      'description': _descriptionController.text,
      'options':
          _optionsWithKeys.map((option) => {'value': option['value']}).toList(),
      'participants': _selectedParticipants,
      'closing_date': _closingDate.toIso8601String(),
      'admin_id': adminId.toString(), // Add admin_id to the voteData map
    };

    try {
      final response = await http.post(
        Uri.parse('http://regestrationrenion.atwebpages.com/vots.php'),
        body: jsonEncode(voteData),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // Vote saved successfully
        _showSnackBar("Vote saved successfully", context);
      } else {
        // Failed to save vote
        _showSnackBar("Failed to save vote", context);
      }
    } catch (e) {
      // Exception occurred
      _showSnackBar("An error occurred", context);
    }
  }

  Future<void> _deleteVote(int voteId) async {
    final response = await http.get(
      Uri.parse(
          'http://regestrationrenion.atwebpages.com/delete_vote.php?vote_id=$voteId&admin_id=$voteId'),
    );

    if (response.statusCode == 200) {
      _showSnackBar("Vote and related data deleted successfully", context);
    } else {
      _showSnackBar("Failed to delete vote and related data", context);
    }
  }

  void _showSnackBar(String message, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Stream<Duration> remainingTimeStream() async* {
    // Calculate the target time (e.g., deadline)
    DateTime targetTime = DateTime.now()
        .add(const Duration(days: 5)); // Example deadline 5 days from now

    while (true) {
      Duration remainingTime = targetTime.difference(DateTime.now());
      yield remainingTime;
      await Future.delayed(
          const Duration(seconds: 1)); // Update the stream every second
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Créer Un Vote',
          style: TextStyle(
            fontFamily: 'Sora',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color.fromRGBO(28, 120, 117, 1),
          ),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30.0),
                        color: const Color.fromRGBO(28, 120, 117, 0.6),
                      ),
                      margin: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                      padding: const EdgeInsets.all(8),
                      child: TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Titre',
                          hintStyle: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Sora',
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30.0),
                        color: const Color.fromRGBO(28, 120, 117, 0.6),
                      ),
                      margin: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                      padding: const EdgeInsets.all(8),
                      child: TextFormField(
                        controller: _descriptionController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'description',
                          hintStyle: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Sora',
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: _optionsWithKeys.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30.0),
                              color: const Color.fromRGBO(28, 120, 117, 0.6),
                            ),
                            margin: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                            padding: const EdgeInsets.all(8),
                            child: TextFormField(
                              initialValue: _optionsWithKeys[index]['value'],
                              onChanged: (newValue) {
                                setState(() {
                                  _optionsWithKeys[index]['value'] = newValue;
                                });
                              },
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Options ${index + 1}',
                                hintStyle: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Sora',
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _optionsWithKeys.removeAt(index);
                              });
                            },
                          ),
                        );
                      },
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30.0),
                              color: const Color.fromRGBO(28, 120, 117, 0.6),
                            ),
                            margin: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                            padding: const EdgeInsets.all(8),
                            child: TextFormField(
                              controller: _newOptionController,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintStyle: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Sora',
                                  fontSize: 16,
                                ),
                                hintText: 'Ajouter une Option',
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add,
                            color: Color.fromRGBO(28, 120, 117, 0.6),
                          ),
                          onPressed: () {
                            setState(() {
                              _optionsWithKeys.add({
                                'key':
                                    'option_${DateTime.now().millisecondsSinceEpoch}_${_optionsWithKeys.length}',
                                'value': _newOptionController.text,
                                'voteCount': 0,
                              });
                              _newOptionController.clear();
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _fetchParticipants(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else if (snapshot.hasData) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30.0),
                                  color:
                                      const Color.fromRGBO(28, 120, 117, 0.6),
                                ),
                                margin: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                                padding: const EdgeInsets.all(8),
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
                                  value: _selectedParticipants.isNotEmpty
                                      ? _selectedParticipants.first
                                      : null,
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      if (newValue != null) {
                                        if (_selectedParticipants
                                            .contains(newValue)) {
                                          _selectedParticipants
                                              .remove(newValue);
                                        } else {
                                          _selectedParticipants.add(newValue);
                                        }
                                      }
                                    });
                                  },
                                  items: snapshot.data != null &&
                                          snapshot.data!.isNotEmpty
                                      ? snapshot.data!
                                          .map<DropdownMenuItem<String>>(
                                              (participant) {
                                          return DropdownMenuItem<String>(
                                            value: '${participant['id']}',
                                            child: Text(
                                              '${participant['name']} ${participant['prename']}',
                                            ),
                                          );
                                        }).toList()
                                      : [
                                          const DropdownMenuItem<String>(
                                            value: null,
                                            child: Text(
                                              'Aucun utilisateur trouvé',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontFamily: 'Sora',
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text('Les Participants Sélectionnés :',
                                  style: TextStyle(
                                    fontFamily: 'Sora',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromRGBO(28, 120, 117, 1),
                                  )),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8.0,
                                children: _selectedParticipants
                                    .map<Widget>((selectedId) {
                                  final selectedParticipant =
                                      snapshot.data!.firstWhere(
                                    (participant) =>
                                        participant['id'] == selectedId,
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
                                            .remove(selectedId);
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          );
                        } else {
                          return const Text('No participants found');
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color.fromRGBO(28, 120, 117, 1),
                        ),
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Color.fromRGBO(28, 120, 117, 1),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Le dernier délai :',
                                  style: TextStyle(
                                    fontFamily: 'Sora',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromRGBO(28, 120, 117, 1),
                                  )),
                              const SizedBox(height: 8),
                              Text(
                                DateFormat('dd/MM/yyyy hh:mm a')
                                    .format(_closingDate),
                                style: const TextStyle(
                                    fontFamily: 'Sora',
                                    fontSize: 16,
                                    color: Color.fromRGBO(58, 65, 69, 1)),
                              ),
                            ],
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromRGBO(
                                  250,
                                  166,
                                  66,
                                  1), // Set the background color of the button
                              // Set button elevation
                            ),
                            onPressed: () async {
                              final selectedDateTime =
                                  await _selectDateTime(context);
                              if (selectedDateTime != null) {
                                setState(() {
                                  _closingDate = selectedDateTime;
                                });
                              }
                            },
                            icon: const Icon(Icons.edit, color: Colors.white),
                            label: const Text(
                              'Changer',
                              style: const TextStyle(
                                  fontFamily: 'Sora',
                                  fontSize: 16,
                                  color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    Row(
                      children: [
                        const SizedBox(
                          width: 400,
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromRGBO(250, 166, 66, 1),
                          ),
                          onPressed: () {
                            _saveVote(
                                context); // Call function to save vote with context
                          },
                          child: const Text(
                            'Sauvegarder',
                            style: const TextStyle(
                                fontFamily: 'Sora',
                                fontSize: 16,
                                color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const VerticalDivider(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Les Résultats des votes',
                      style: TextStyle(
                        color: Color.fromRGBO(28, 120, 117, 1),
                        fontFamily: 'Sora',
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _fetchOptionVotes(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasError) {
                          return const Text('Pas De Vote Trouvé');
                        } else if (snapshot.hasData &&
                            snapshot.data!.isNotEmpty) {
                          // Group options by vote_id
                          Map<int, List<Map<String, dynamic>>> groupedOptions =
                              {};
                          snapshot.data!.forEach((option) {
                            int? voteId;
                            if (option['vote_id'] is int) {
                              voteId = option['vote_id'];
                            } else if (option['vote_id'] is String) {
                              voteId = int.tryParse(option['vote_id']);
                            }

                            if (!groupedOptions.containsKey(voteId)) {
                              groupedOptions[voteId!] = [];
                            }
                            groupedOptions[voteId]!.add(option);
                          });

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:
                                groupedOptions.entries.map<Widget>((entry) {
                              int voteId = entry.key;
                              String title = entry.value[0]['title'] ?? '';
                              String description =
                                  entry.value[0]['description'] ?? '';
                              int totalVotes = entry.value.fold(
                                0,
                                (total, option) =>
                                    total +
                                    (int.parse(
                                            option['vote_count'].toString()) ??
                                        0),
                              );

                              // Calculate remaining time
                              DateTime closingDate = DateTime.parse(
                                  entry.value[0]['closing_date']);
                              Duration remainingTime =
                                  closingDate.difference(DateTime.now());

                              return Container(
                                margin: const EdgeInsets.only(bottom: 24.0),
                                decoration: BoxDecoration(
                                  image: const DecorationImage(
                                    image: AssetImage('assets/images/45.png'),
                                    fit: BoxFit.cover,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        SizedBox(
                                            height: 50,
                                            width: 50,
                                            child: Image.asset(
                                                'assets/images/pu2.png')),
                                        Text(
                                          ' $title',
                                          style: const TextStyle(
                                            fontFamily: 'Sora',
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 40),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          color: Colors.red,
                                          onPressed: () async {
                                            await _deleteVote(voteId);
                                            setState(() {});
                                          },
                                        ),
                                        const Text(
                                          "Supprimé",
                                          style: const TextStyle(
                                            fontFamily: 'Sora',
                                            color: Colors.white,
                                          ),
                                        )
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      ' $description',
                                      style: const TextStyle(
                                        fontFamily: 'Sora',
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Les Votes :',
                                      style: TextStyle(
                                        fontFamily: 'Sora',
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children:
                                          entry.value.map<Widget>((option) {
                                        String optionValue =
                                            option['option_value'] ?? '';
                                        int voteCount = int.tryParse(
                                                option['vote_count']
                                                    .toString()) ??
                                            0;

                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                optionValue.isNotEmpty
                                                    ? optionValue
                                                    : 'Unknown Option',
                                                style: const TextStyle(
                                                  fontFamily: 'Sora',
                                                  fontSize: 16,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              Text(
                                                'nombre de votes: $voteCount',
                                                style: const TextStyle(
                                                  fontFamily: 'Sora',
                                                  fontSize: 16,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.white,
                                                ),
                                                onPressed: () {
                                                  _viewVotingParticipants(
                                                      optionValue);
                                                },
                                                child: const Text(
                                                  'Participants',
                                                  style: const TextStyle(
                                                    fontFamily: 'Sora',
                                                    fontSize: 16,
                                                    color: Color.fromRGBO(
                                                        58, 65, 69, 1),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Total des votes pour toutes les options: $totalVotes',
                                      style: const TextStyle(
                                        fontFamily: 'Sora',
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8.0, horizontal: 16.0),
                                      decoration: BoxDecoration(
                                        color: const Color.fromRGBO(
                                            28, 120, 117, 0.6),
                                        borderRadius:
                                            BorderRadius.circular(20.0),
                                      ),
                                      child: StreamBuilder<Duration>(
                                        stream:
                                            remainingTimeStream(), // Assuming you have a stream that emits the remaining time
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData) {
                                            if (remainingTime.inSeconds <= 0) {
                                              return const Text(
                                                'Votre vote est terminé !',
                                                style: TextStyle(
                                                  fontFamily: 'Sora',
                                                  fontSize: 16,
                                                  color: Colors.white,
                                                ),
                                              );
                                            } else {
                                              return Text(
                                                'Temps Restant: ${remainingTime.inDays} jours ${remainingTime.inHours.remainder(24)} heures ${remainingTime.inMinutes.remainder(60)} minutes ${remainingTime.inSeconds.remainder(60)} seconds',
                                                style: const TextStyle(
                                                  fontFamily: 'Sora',
                                                  fontSize: 16,
                                                  color: Colors.white,
                                                ),
                                              );
                                            }
                                          } else if (snapshot.hasError) {
                                            return Text(
                                              'Erreur: ${snapshot.error}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.white,
                                              ),
                                            );
                                          } else {
                                            return const Text(
                                              'Loading...',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.white,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        } else {
                          return const Center(
                            child: Column(
                              children: [
                                Text(
                                  'No votes set yet',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Icon(
                                  Icons.sentiment_dissatisfied,
                                  size: 48,
                                  color: Colors.blue,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Check back later for updates!',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchOptionVotes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int adminId = prefs.getInt('admin_id') ?? 0;
    final response = await http.get(
      Uri.parse(
          'http://regestrationrenion.atwebpages.com/option_votes.php?admin_id=$adminId'),
    );

    if (response.statusCode == 200) {
      List<Map<String, dynamic>> optionVotes =
          List<Map<String, dynamic>>.from(jsonDecode(response.body));
      return optionVotes;
    } else {
      _showSnackBar(
          "Error: Failed to fetch option votes. Status code", context);

      return [];
    }
  }

  void _viewVotingParticipants(String optionValue) async {
    try {
      final response = await http.post(
        Uri.parse(
            'http://regestrationrenion.atwebpages.com/show_participants.php'),
        body: {'option_value': optionValue},
      );

      if (response.statusCode == 200) {
        final List<Map<String, dynamic>> participants =
            List<Map<String, dynamic>>.from(jsonDecode(response.body));

        // Display names and prenames of participants who voted for this option
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Participants who voted for Option $optionValue'),
              content: Container(
                width: double.maxFinite,
                constraints: const BoxConstraints(
                    maxHeight: 400), // Adjust the maximum height as needed
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Total Participants: ${participants.length}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(), // Ensure the ListView does not scroll
                        itemCount: participants.length,
                        itemBuilder: (context, index) {
                          final participant = participants[index];
                          return ListTile(
                            title: Text(
                                '${participant['participant_name']} ${participant['participant_prename']}'),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      } else {
        _showSnackBar("Failed to fetch participants", context);
      }
    } catch (e) {
      _showSnackBar("$e", context);
    }
  }
}
