import 'package:flutter/material.dart';
import 'package:sgovs/home/bibliotheque.dart';
import 'package:sgovs/home/bourse/bourse.dart';
import 'package:sgovs/home/chat/chat.dart';
import 'package:sgovs/home/cree_vote/CreateVotePage.dart';
import 'package:sgovs/home/gerer_utilisateurs/manage_users_page.dart';
import 'package:sgovs/home/login.dart';
import 'package:sgovs/home/orgnize_renion/Orgnize_Renion.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isLoggedIn = false;
  String userName = '';
  String userPrename = '';

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      if (isLoggedIn) {
        userName = prefs.getString('admin_name') ?? '';
        userPrename = prefs.getString('admin_prename') ?? '';
      }
    });
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    setState(() {
      isLoggedIn = false;
    });
    // Navigate to the login page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Login()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isLoggedIn ? 'Bienvenue $userName $userPrename' : 'SGovs'),
        actions: [
          if (isLoggedIn)
            IconButton(
              onPressed: logout,
              icon: const Icon(Icons.logout,color: Colors.red,),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ManageUsersPage()),
                  );
                },
                child: const Text('Gérer les utilisateurs'),
              ),
              SizedBox(height: 10,),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) =>  ChatPage()),
                  );
                },
                child: const Text('Chat Room'),
              ),
              const SizedBox(height: 60),
              SizedBox(
                height: 280, // Set a fixed height for the row
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFeatureContainer(
                        'Organiser une Réunion',
                        'assets/images/v.png',
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const Orgnize_Renion(title: 'Organize un renion',)),
                        ),
                      ),
                      _buildFeatureContainer(
                        'Créer un Vote',
                        'assets/images/v2.png',
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CreateVotePage()),
                        ),
                      ),
                      _buildFeatureContainer(
                        'Bibliothèque numérique',
                        'assets/images/b2.png',
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LibraryPage()),
                        ),
                      ),
                      _buildFeatureContainer(
                        'Bourses',
                        'assets/images/bb2.png',
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Bourse()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureContainer(String text, String imagePath, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        width: 200,
        decoration: BoxDecoration(
          color: const Color.fromRGBO(28, 120, 117, 0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 150, height: 100, child: Image.asset(imagePath)),
            const SizedBox(height: 10),
            Text(
              text,
              style: const TextStyle(fontFamily: 'Sora', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
