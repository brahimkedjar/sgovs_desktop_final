import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'User Management App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ManageUsersPage(),
    );
  }
}

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({Key? key}) : super(key: key);

  @override
  _ManageUsersPageState createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  List<User> _users = [];
  bool _isLoading = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _prenameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _autrePostController = TextEditingController();
  final TextEditingController _autreAppartenanceController = TextEditingController();

bool showAutrePostTextField = false;
  bool showAutreAppartenanceTextField = false;
  String? selectedPost;
  String? selectedAppartenance;
  String? selectedUtilisateur;
  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int adminId = prefs.getInt('admin_id') ?? 0;

    final response = await http.get(
        Uri.parse('http://regestrationrenion.atwebpages.com/api.php?admin_id=$adminId'));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData is List) {
        setState(() {
          _users =
              jsonData.map((userJson) => User.fromJson(userJson)).toList();
          _isLoading = false;
        });
      } else {
        print('Unexpected response format: $jsonData');
      }
    } else {
      print('HTTP error: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Manage Users'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildUserForm(),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => UsersListPage(users: _users)),
          );
        },
        child: const Icon(Icons.people),
      ),
    );
  }

  Widget _buildUserForm() {
  

  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Create New User',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _prenameController,
          decoration: const InputDecoration(
            labelText: 'Prename',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          decoration: const InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: selectedPost,
          onChanged: (value) {
            setState(() {
              selectedPost = value;
              showAutrePostTextField = value == 'autre';
            });
          },
          items: const [
            DropdownMenuItem(
              value: 'Actionnaire',
              child: Text('Actionnaire'),
            ),
            DropdownMenuItem(
              value: 'Dirigeant',
              child: Text('Dirigeant'),
            ),
            DropdownMenuItem(
              value: 'Administrateur',
              child: Text('Administrateur'),
            ),
            DropdownMenuItem(
              value: 'Commissaire aux comptes',
              child: Text('Commissaire aux comptes'),
            ),
            DropdownMenuItem(
              value: 'autre',
              child: Text('Autre'),
            ),
          ],
          decoration: const InputDecoration(
            labelText: 'Post',
            border: OutlineInputBorder(),
          ),
        ),
        if (showAutrePostTextField)
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Autre Post',
              border: OutlineInputBorder(),
            ),
          ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: selectedAppartenance,
          onChanged: (value) {
            setState(() {
              selectedAppartenance = value;
              showAutreAppartenanceTextField = value == 'autre';
            });
          },
          items: const [
            DropdownMenuItem(
              value: 'conseil d\'administration',
              child: Text('Conseil d\'administration'),
            ),
            DropdownMenuItem(
              value: 'assamblée genéral',
              child: Text('Assamblé genéral'),
            ),
            DropdownMenuItem(
              value: 'comité d\'audit',
              child: Text('Comité d\'audit'),
            ),
            DropdownMenuItem(
              value: 'comité de RH',
              child: Text('Comité de RH'),
            ),
            DropdownMenuItem(
              value: 'comité stratégique',
              child: Text('Comité stratégique'),
            ),
            DropdownMenuItem(
              value: 'autre',
              child: Text('Autre'),
            ),
          ],
          decoration: const InputDecoration(
            labelText: 'Appartenance',
            border: OutlineInputBorder(),
          ),
        ),
        if (showAutreAppartenanceTextField)
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Autre Appartenance',
              border: OutlineInputBorder(),
            ),
          ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: selectedUtilisateur,
          onChanged: (value) {
            setState(() {
              selectedUtilisateur = value;
            });
          },
          items: const [
            DropdownMenuItem(
              value: 'dépendant',
              child: Text('Dépendant'),
            ),
            DropdownMenuItem(
              value: 'indépendant',
              child: Text('Indépendant'),
            ),
          ],
          decoration: const InputDecoration(
            labelText: 'Utilisateur',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _addUser,
          child: const Text('Add User'),
        ),
      ],
    ),
  );
}


 // Dart code for adding a user
void _addUser() async {
  final String name = _nameController.text;
  final String prename = _prenameController.text;
  final String email = _emailController.text;
  final String password = _passwordController.text;
  final String phoneNumber = _phoneController.text;
  final String? autrePost = showAutrePostTextField ? _autrePostController.text : null;
  final String? autreAppartenance = showAutreAppartenanceTextField ? _autreAppartenanceController.text : null;
  final String? utilisateur = selectedUtilisateur;

  if (name.isNotEmpty &&
      prename.isNotEmpty &&
      email.isNotEmpty &&
      password.isNotEmpty &&
      phoneNumber.isNotEmpty &&
      utilisateur != null) {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int adminId = prefs.getInt('admin_id') ?? 0;

    final response = await http.post(
      Uri.parse('http://regestrationrenion.atwebpages.com/api.php'),
      body: {
        'name': name,
        'prename': prename,
        'email': email,
        'password': password,
        'phone_number': phoneNumber,
        'post': selectedPost ?? '',
        'appartenance': selectedAppartenance ?? '',
        'utilisateur': utilisateur,
        if (autrePost != null) 'autre_post': autrePost,
        if (autreAppartenance != null) 'autre_appartenance': autreAppartenance,
        'admin_id': adminId.toString(),
      },
    );

    if (response.statusCode == 200) {
final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['id'] != null) {
        // Add the user to the local list
        setState(() {
          _users.add(User(
            id: jsonResponse['id'],
            name: name,
            prename: prename,
            email: email,
            password: password,
            phoneNumber: phoneNumber,
            post: selectedPost,
            appartenance: selectedAppartenance,
            utilisateur: utilisateur,
            autrePost: autrePost,
            autreAppartenance: autreAppartenance,
          ));
        });
        // Clear text controllers
        _nameController.clear();
        _prenameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _phoneController.clear();
        if (showAutrePostTextField) _autrePostController.clear();
        if (showAutreAppartenanceTextField) _autreAppartenanceController.clear();
        // Show success message
        _showSnackBar(context, 'User added successfully', Colors.green);
      } else {
        // Show error message
        _showSnackBar(context, 'Failed to add user: ${jsonResponse['error']}', Colors.red);
      }
    } else {
      // Show error message
      _showSnackBar(context, 'Failed to add user: ${response.reasonPhrase}', Colors.red);
    }
  } else {
    // Show error message
    _showSnackBar(context, 'All fields are required', Colors.red);
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
}

class User {
  final int id;
  late String name; 
  late String prename;
  late String email;
  late String password;
  late String phoneNumber; // New field
  late String? post; // New nullable field
  late String? autrePost; // New nullable field
  late String? appartenance; // New nullable field
  late String? autreAppartenance; // New nullable field
  late String? utilisateur; // New nullable field

  User({
    required this.id,
    required this.name,
    required this.prename,
    required this.email,
    required this.password,
    required this.phoneNumber, // Add phoneNumber to constructor
    this.post, // Add post to constructor
    this.autrePost, // Add autrePost to constructor
    this.appartenance, // Add appartenance to constructor
    this.autreAppartenance, // Add autreAppartenance to constructor
    this.utilisateur, // Add utilisateur to constructor
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) ?? 0 : 0,
      name: json['name'] as String,
      prename: json['prename'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
    phoneNumber: json['phone_number'] != null ? json['phone_number'] as String : '', // Handle null value
      post: json['post'] as String?, // Map post from JSON
      autrePost: json['autre_post'] as String?, // Map autrePost from JSON
      appartenance: json['appartenance'] as String?, // Map appartenance from JSON
      autreAppartenance: json['autre_appartenance'] as String?, // Map autreAppartenance from JSON
      utilisateur: json['utilisateur'] as String?, // Map utilisateur from JSON
    );
  }
}


class UsersListPage extends StatefulWidget {
  final List<User> users;

  const UsersListPage({Key? key, required this.users}) : super(key: key);

  @override
  _UsersListPageState createState() => _UsersListPageState();
}

class _UsersListPageState extends State<UsersListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User List'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Existing Users',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: DataTable(
                    columnSpacing: 20,
                    headingRowColor:
                        MaterialStateColor.resolveWith((states) => Colors.blue[200]!),
                    dataRowColor:
                        MaterialStateColor.resolveWith((states) => Colors.blue[50]!),
                    columns: const [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Prename')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Password')),
                      DataColumn(label: Text('Phone Number')),
                      DataColumn(label: Text('Post')),
                      DataColumn(label: Text('Appartenance')),
                      DataColumn(label: Text('Utilisateur')),
                      DataColumn(label: Text('Delete')),
                      DataColumn(label: Text('Modify')),
                    ],
                    rows: widget.users.map((user) {
                      return DataRow(cells: [
                        DataCell(Text(user.id.toString())),
                        DataCell(Text(user.name)),
                        DataCell(Text(user.prename)),
                        DataCell(Text(user.email)),
                        DataCell(Text(user.password)),
                        DataCell(Text(user.phoneNumber)),
                        DataCell(Text(user.post ?? 'N/A')),
                        DataCell(Text(user.appartenance ?? 'N/A')),
                        DataCell(Text(user.utilisateur ?? 'N/A')),
                        DataCell(
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () async {
                              await _deleteUser(context, user.id);
                              setState(() {}); // Refresh the UI after deletion
                            },
                          ),
                        ),
                        DataCell(
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              _modifyUser(context, user);
                            },
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteUser(BuildContext context, int userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int adminId = prefs.getInt('admin_id') ?? 0;

    final response = await http.delete(
      Uri.parse('http://regestrationrenion.atwebpages.com/api.php'),
      body: {
        'id': userId.toString(),
        'admin_id': adminId.toString(),
      },
    );

    if (response.statusCode == 200) {
      // Remove the deleted user from the list
      setState(() {
        widget.users.removeWhere((user) => user.id == userId);
      });
      _showSnackBar(context, 'User deleted successfully', Colors.green);
    } else {
      _showSnackBar(context, 'Failed to delete user', Colors.red);
    }
  }

  void _modifyUser(BuildContext context, User user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModifyUserPage(user: user),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }
}


class ModifyUserPage extends StatefulWidget {
  final User user;

  const ModifyUserPage({Key? key, required this.user}) : super(key: key);

  @override
  _ModifyUserPageState createState() => _ModifyUserPageState();
}

class _ModifyUserPageState extends State<ModifyUserPage> {
  late TextEditingController _nameController;
  late TextEditingController _prenameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _phoneNumberController;
  String _selectedPost = '';
  String _selectedAppartenance = '';
  String _selectedUtilisateur = '';
  late TextEditingController _autrePostController;
  late TextEditingController _autreAppartenanceController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _prenameController = TextEditingController(text: widget.user.prename);
    _emailController = TextEditingController(text: widget.user.email);
    _passwordController = TextEditingController(text: widget.user.password);
    _phoneNumberController = TextEditingController(text: widget.user.phoneNumber);
    _selectedPost = widget.user.post!;
    _selectedAppartenance = widget.user.appartenance!;
    _selectedUtilisateur = widget.user.utilisateur!;
    _autrePostController = TextEditingController();
    _autreAppartenanceController = TextEditingController();
    _autrePostController.text = widget.user.autrePost ?? '';
    _autreAppartenanceController.text = widget.user.autreAppartenance ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modify User'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextFormField(
              controller: _prenameController,
              decoration: const InputDecoration(labelText: 'Prename'),
            ),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            TextFormField(
              controller: _phoneNumberController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
            ),
            DropdownButtonFormField<String>(
              value: _selectedPost,
              onChanged: (newValue) {
                setState(() {
                  _selectedPost = newValue!;
                });
              },
              items: ['Actionnaire', 'Dirigeant', 'Administrateur', 'Commissaire au compte', 'Autre']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              decoration: const InputDecoration(labelText: 'Post'),
            ),
            if (_selectedPost == 'Autre')
              TextFormField(
                controller: _autrePostController,
                decoration: const InputDecoration(labelText: 'Autre Post'),
              ),
            DropdownButtonFormField<String>(
  value: _selectedAppartenance,
  onChanged: (newValue) {
    setState(() {
      _selectedAppartenance = newValue!;
    });
  },
  items: const [
    DropdownMenuItem<String>(
      value: 'Conseil d\'administration',
      child: Text('Conseil d\'administration'),
    ),
    DropdownMenuItem<String>(
      value: 'Assemblée générale',
      child: Text('Assemblée générale'),
    ),
    DropdownMenuItem<String>(
      value: 'Comité d\'audit',
      child: Text('Comité d\'audit'),
    ),
    DropdownMenuItem<String>(
      value: 'Comité de RM',
      child: Text('Comité de RM'),
    ),
    DropdownMenuItem<String>(
      value: 'Comité stratégique',
      child: Text('Comité stratégique'),
    ),
    DropdownMenuItem<String>(
      value: 'Autre',
      child: Text('Autre'),
    ),
  ],
  decoration: const InputDecoration(labelText: 'Appartenance'),
),

            if (_selectedAppartenance == 'Autre')
              TextFormField(
                controller: _autreAppartenanceController,
                decoration: const InputDecoration(labelText: 'Autre Appartenance'),
              ),
            DropdownButtonFormField<String>(
              value: _selectedUtilisateur,
              onChanged: (newValue) {
                setState(() {
                  _selectedUtilisateur = newValue!;
                });
              },
              items: ['Dépendant', 'Indépendant']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              decoration: const InputDecoration(labelText: 'Utilisateur'),
            ),
            ElevatedButton(
              onPressed: _updateUser,
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateUser() async {
  // Get the updated values from the controllers
  final String name = _nameController.text;
  final String prename = _prenameController.text;
  final String email = _emailController.text;
  final String password = _passwordController.text;
  final String phoneNumber = _phoneNumberController.text;

  // Get the admin_id from SharedPreferences
  SharedPreferences prefs = await SharedPreferences.getInstance();
  int adminId = prefs.getInt('admin_id') ?? 0;

  final response = await http.put(
  Uri.parse('http://regestrationrenion.atwebpages.com/api.php'),
  body: {
    'id': widget.user.id.toString(), // User ID
    'name': name,
    'prename': prename,
    'email': email,
    'password': password,
    'phone_number': phoneNumber,
    'post': _selectedPost,
    'appartenance': _selectedAppartenance,
    'utilisateur': _selectedUtilisateur,
    if (_selectedPost == 'Autre') 'autre_post': _autrePostController.text,
    if (_selectedAppartenance == 'Autre') 'autre_appartenance': _autreAppartenanceController.text,
    'admin_id': adminId.toString(),
  },
);

  if (response.statusCode == 200) {
    // Update the user data in the local list
    setState(() {
      widget.user.name = name;
      widget.user.prename = prename;
      widget.user.email = email;
      widget.user.password = password;
      widget.user.phoneNumber = phoneNumber;
      widget.user.post = _selectedPost;
      widget.user.appartenance = _selectedAppartenance;
      widget.user.utilisateur = _selectedUtilisateur;
      if (_selectedPost == 'Autre') widget.user.autrePost = _autrePostController.text;
      if (_selectedAppartenance == 'Autre') widget.user.autreAppartenance = _autreAppartenanceController.text;
    });
    // Show a success message
    _showSnackBar(context, 'User updated successfully', Colors.green);
  } else {
    // Show an error message
    _showSnackBar(context, 'Failed to update user', Colors.red);
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
  void dispose() {
    _nameController.dispose();
    _prenameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneNumberController.dispose();
    _autrePostController.dispose();
    _autreAppartenanceController.dispose();
    super.dispose();
  }
}

