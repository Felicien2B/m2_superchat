import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  final String displayName;
  final String bio;

  const ProfilePage({
    Key? key,
    required this.displayName,
    required this.bio,
  }) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _displayNameController;
  late TextEditingController _bioController;
  String _feedbackMessage = '';

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(text: widget.displayName);
    _bioController = TextEditingController(text: widget.bio);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profil'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nom d\'utilisateur',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextFormField(
              controller: _displayNameController,
              decoration: InputDecoration(
                hintText: 'Nom d\'utilisateur',
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Bio',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextFormField(
              controller: _bioController,
              decoration: InputDecoration(
                hintText: 'Bio',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _updateProfile();
              },
              child: Text('Enregistrer'),
            ),
            SizedBox(height: 20),
            Text(
              _feedbackMessage,
              style: TextStyle(
                color: _feedbackMessage.contains('Succès') ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateProfile() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final newDisplayName = _displayNameController.text.trim();
      final newBio = _bioController.text.trim();

      if (newDisplayName.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .where('id', isEqualTo: currentUser.uid)
            .get()
            .then((querySnapshot) {
          if (querySnapshot.docs.isNotEmpty) {
            final docID = querySnapshot.docs.first.id;
            FirebaseFirestore.instance
                .collection('users')
                .doc(docID)
                .update({
              'displayName': newDisplayName,
              'bio': newBio,
            }).then((_) {
              setState(() {
                _feedbackMessage = 'Succès: Profil mis à jour !';
              });
            }).catchError((error) {
              setState(() {
                _feedbackMessage = 'Erreur: Impossible de mettre à jour le profil.';
              });
            });
          } else {
            setState(() {
              _feedbackMessage = 'Erreur: Utilisateur non trouvé.';
            });
          }
        });
      } else {
        setState(() {
          _feedbackMessage = 'Erreur: Le nom d\'utilisateur ne peut pas être vide.';
        });
      }
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}
