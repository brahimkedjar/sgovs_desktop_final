import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FileItem {
  final int id;
  final String name;
  final String link;
  final String dateSaved;

  FileItem({
    required this.id,
    required this.name,
    required this.link,
    required this.dateSaved,
  });
}

class LibraryPage extends StatefulWidget {
  @override
  _LibraryPageState createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  List<FileItem> _files = [];
  bool _isLoading = false;
  late TextEditingController _nameController;
  late TextEditingController _linkController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _linkController = TextEditingController();
    _getFiles();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  final List<String> _selectedParticipants = [];
  String _errorMessage = '';
  String _successMessage = '';
void _showSnackBar(String message, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
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

  Future<void> _getFiles() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.get(Uri.parse(
          'http://regestrationrenion.atwebpages.com/bibliotheques.php'));
      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        setState(() {
          _files = responseData
    .map((file) => FileItem(
          id: int.parse(file['id']), // Parse 'id' to an int
          name: file['name'],
          link: file['link'],
          dateSaved: file['date_saved'],
        ))
    .toList();
        });
      } else {
        throw Exception('Failed to load files');
      }
    } catch (e) {
      _errorMessage = 'Failed to load files';
      print('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

 Future<void> _addFile() async {
  final String name = _nameController.text.trim();
  final String link = _linkController.text.trim();
  if (name.isNotEmpty && link.isNotEmpty) {
    try {
      final List<String> participantIds = _selectedParticipants.toList();
      final response = await http.post(
        Uri.parse('http://regestrationrenion.atwebpages.com/bibliotheques.php'),
        body: {
          'action': 'add',
          'name': name,
          'link': link,
          'participant_ids': json.encode(participantIds), // Convert to JSON string
        },
      );
      if (response.statusCode == 200) {
        _successMessage = 'File added successfully';
        _nameController.clear();
        _linkController.clear();
        await _getFiles();
      } else {
        _errorMessage = 'Failed to add file';
        throw Exception('Failed to add file');
      }
    } catch (e) {
      _errorMessage = 'Failed to add file';
      print('Error: $e');
    }
  } else {
    _errorMessage = 'Please enter file name and link';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Please enter file name and link.'),
      ),
    );
  }
}


  Future<void> _deleteFile(int id) async {
    try {
      final response = await http.post(
        Uri.parse('http://regestrationrenion.atwebpages.com/bibliotheques.php'),
        body: {
          'action': 'delete',
          'id': id.toString(),
        },
      );
      if (response.statusCode == 200) {
        _successMessage = 'File deleted successfully';
        await _getFiles();
      } else {
        _errorMessage = 'Failed to delete file';
        throw Exception('Failed to delete file');
      }
    } catch (e) {
      _errorMessage = 'Failed to delete file';
      print('Error: $e');
    }
  }

  Future<void> _showEditDialog(FileItem file, List<Map<String, dynamic>> participants) async {
  _nameController.text = file.name;
  _linkController.text = file.link;

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Edit File'),
        content: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'File Name'),
                  ),
                  TextField(
                    controller: _linkController,
                    decoration: InputDecoration(labelText: 'File Link'),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select Participants',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text('Select participants'),
                    value: _selectedParticipants.isNotEmpty
                        ? _selectedParticipants.first
                        : null,
                    onChanged: (String? newValue) {
                      setState(() {
                        if (newValue != null) {
                          if (_selectedParticipants.contains(newValue)) {
                            _selectedParticipants.remove(newValue);
                          } else {
                            _selectedParticipants.add(newValue);
                          }
                        }
                      });
                    },
                    items: participants
                        .map<DropdownMenuItem<String>>((participant) {
                      return DropdownMenuItem<String>(
                        value: '${participant['id']}',
                        child: Text(
                            '${participant['name']} ${participant['prename']}'),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 8),
                  Text('Selected Participants:'),
                  Wrap(
                    children: _selectedParticipants
                        .map((participantId) {
                      final participant = participants.firstWhere(
                        (element) => element['id'] == participantId,
                        orElse: () => {}, // Provide default value here
                      );
                      if (participant.isNotEmpty) {
                        return Chip(
                          label: Text(
                              '${participant['name']} ${participant['prename']}'),
                          onDeleted: () {
                            setState(() {
                              _selectedParticipants.remove(participantId);
                            });
                          },
                        );
                      }
                      return SizedBox.shrink();
                    }).toList(),
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _updateFile(file.id);
              Navigator.of(context).pop();
            },
            child: Text('Update'),
          ),
        ],
      );
    },
  );
}

  Future<void> _updateFile(int id) async {
  final String name = _nameController.text.trim();
  final String link = _linkController.text.trim();
  if (name.isNotEmpty && link.isNotEmpty) {
    try {
      final List<String> participantIds = _selectedParticipants.toList();
      final response = await http.post(
        Uri.parse('http://regestrationrenion.atwebpages.com/bibliotheques.php'),
        body: {
          'action': 'modify', // Change action to 'modify'
          'id': id.toString(),
          'name': name,
          'link': link,
          'participant_ids': json.encode(participantIds), // Convert to JSON string
        },
      );
      if (response.statusCode == 200) {
        _successMessage = 'File updated successfully';
        _nameController.clear();
        _linkController.clear();
        await _getFiles();
      } else {
        _errorMessage = 'Failed to update file';
        throw Exception('Failed to update file');
      }
    } catch (e) {
      _errorMessage = 'Failed to update file';
      print('Error: $e');
    }
  } else {
    _errorMessage = 'Please enter file name and link';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Please enter file name and link.'),
      ),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Library'),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
              itemCount: _files.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  child: InkWell(
                    onTap: () {
                      // Implement navigation to file link
                    },
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: Offset(0, 2), // changes position of shadow
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Nom de Livre : ',style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,)
                                    ),
                                    Text(
                                  _files[index].name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                  ],
                                ),
                                
                                SizedBox(height: 5),
                                Text(
                                  'Date Saved: ${_files[index].dateSaved}',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
  icon: Icon(Icons.edit),
  onPressed: () async {
    final participants = await _fetchParticipants();
    _showEditDialog(_files[index], participants);
  },
),

                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => _deleteFile(_files[index].id),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFileDialog,
        tooltip: 'Add File',
        child: Icon(Icons.add),
      ),
    );
  }
void _showAddFileDialog() {
  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchParticipants(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (snapshot.hasData) {
                return AlertDialog(
                  title: Text('Add File'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(labelText: 'File Name'),
                        ),
                        TextField(
                          controller: _linkController,
                          decoration: InputDecoration(labelText: 'File Link'),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Select Participants',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButton<String>(
                          isExpanded: true,
                          hint: const Text('Select participants'),
                          value: _selectedParticipants.isNotEmpty
                              ? _selectedParticipants.first
                              : null,
                          onChanged: (String? newValue) {
                            setState(() {
                              if (newValue != null) {
                                if (_selectedParticipants.contains(newValue)) {
                                  _selectedParticipants.remove(newValue);
                                } else {
                                  _selectedParticipants.add(newValue);
                                }
                              }
                            });
                          },
                          items: snapshot.data!
                              .map<DropdownMenuItem<String>>((participant) {
                            return DropdownMenuItem<String>(
                              value: '${participant['id']}',
                              child: Text(
                                  '${participant['name']} ${participant['prename']}'),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 8),
                        Text('Selected Participants:'),
                        Wrap(
                          children: _selectedParticipants
                              .map((participantId) {
                            final participant = snapshot.data!.firstWhere(
                              (element) => element['id'] == participantId,
                              orElse: () => {}, // Provide default value here
                            );
                            if (participant.isNotEmpty) {
                              return Chip(
                                label: Text(
                                    '${participant['name']} ${participant['prename']}'),
                                onDeleted: () {
                                  setState(() {
                                    _selectedParticipants.remove(participantId);
                                  });
                                },
                              );
                            }
                            return SizedBox.shrink();
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await _addFile();
                        if (_successMessage.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_successMessage),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else if (_errorMessage.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_errorMessage),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        Navigator.of(context).pop();
                      },
                      child: Text('Add'),
                    ),
                  ],
                );
              } else {
                return Center(child: Text('No participants found'));
              }
            },
          );
        },
      );
    },
  );
}

}

void main() {
  runApp(MaterialApp(
    home: LibraryPage(),
  ));
}
