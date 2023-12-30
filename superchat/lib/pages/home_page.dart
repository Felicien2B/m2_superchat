import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:superchat/pages/chat_page.dart';
import 'package:superchat/pages/sign_in_page.dart';
import 'package:superchat/pages/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? selectedUserID;
  // Récupération des informations de l'utilisateur à partir de Firestore
  Future<Map<String, dynamic>> _getUserProfileData(String userID) async {
    final DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userID)
        .get();

    return userSnapshot.data() as Map<String, dynamic>;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Erreur: ${snapshot.error}'),
            ),
          );
        }

        if (snapshot.data == null) {
          return const Scaffold(
            body: Center(
              child: Text('Aucun utilisateur connecté.'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Superchat'),
            backgroundColor: theme.colorScheme.primary,
            actions: [
              // Bouton de déconnexion
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => SignInPage()),
                  );
                },
              ),
              // Bouton d'accès au profil
              IconButton(
                icon: Icon(Icons.person),
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    final userSnapshot = await FirebaseFirestore.instance
                        .collection('users')
                        .where('id', isEqualTo: user.uid)
                        .get();

                    if (userSnapshot.docs.isNotEmpty) {
                      final userData = userSnapshot.docs.first.data() as Map<String, dynamic>;
                      final displayName = userData['displayName'] ?? '';
                      final bio = userData['bio'] ?? '';

                      if (displayName.isNotEmpty) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProfilePage(
                              displayName: displayName,
                              bio: bio,
                            ),
                          ),
                        );
                      } else {
                        print('Nom d\'utilisateur non trouvé');
                      }
                    } else {
                      print('Données utilisateur non trouvées');
                    }
                  }
                },
              ),
            ],
          ),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildUserList(),
              ),
              Expanded(
                flex: 5,
                child: selectedUserID != null
                    ? FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .where('id', isEqualTo: selectedUserID)
                      .get(),
                  builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    }
                    if (snapshot.hasError) {
                      return Text('Erreur: ${snapshot.error}');
                    }
                    if (!snapshot.hasData) {
                      return Text('Aucune donnée trouvée');
                    }

                    final userDoc = snapshot.data?.docs.first;
                    if (userDoc != null) {
                      final userData = userDoc.data() as Map<String, dynamic>;
                      final selectedUserDisplayName = userData['displayName'] as String?;
                      final selectedUserBio = userData['bio'] as String?;
                      return ChatPage(
                        selectedUserID: selectedUserID!,
                        selectedUserDisplayName: selectedUserDisplayName ?? 'Utilisateur',
                        selectedUserBio: selectedUserBio ?? '',
                      );
                    } else {
                      return Text('Utilisateur introuvable');
                    }
                  },
                )
                    : Container(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserList() {
    final currentUserID = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Erreur de chargement'));
        }

        final users = snapshot.data?.docs ?? [];

        final filteredUsers = users.where((user) {
          final userData = user.data() as Map<String, dynamic>;
          final userID = userData['id'];
          final displayName = userData['displayName'];
          return userID != null && displayName != null;
        }).toList();

        return ListView.builder(
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final userData = filteredUsers[index].data() as Map<String, dynamic>;
            final userID = userData['id'];
            final displayName = userData['displayName'];

            if (userID == currentUserID) {
              return const SizedBox();
            }

            return ListTile(
              title: Text(displayName),
              onTap: () {
                setState(() {
                  selectedUserID = userID;
                });
              },
            );
          },
        );
      },
    );
  }
}
