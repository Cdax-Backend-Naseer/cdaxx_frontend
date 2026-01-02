import 'package:flutter/material.dart';
import '../application/profile_provider.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key, this.initial});
  final UserProfile? initial;

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _phone;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.initial ??
        const UserProfile(
          name: 'Jane Doe',
          email: 'jane@example.com',
          phone: '+1 555 0100',
          enrolledCoursesCount: 2,
          subscribed: true,
        );
    _name = TextEditingController(text: p.name);
    _phone = TextEditingController(text: p.phone);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.initial ??
        const UserProfile(
          name: '',
          email: '',
          phone: '',
          enrolledCoursesCount: 1,
          subscribed: true,
        );

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Name',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withOpacity(0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Name is required';
                if (v.trim().length < 2) return 'Enter a valid name';
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: profile.email,
              style: const TextStyle(color: Colors.white70),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withOpacity(0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              readOnly: true,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phone,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Phone',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withOpacity(0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Phone is required';
                final d = v.replaceAll(RegExp('[^0-9]'), '');
                if (d.length < 10) return 'Enter a valid phone number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF38BDF8),
                foregroundColor: Colors.white,
              ),
              onPressed: _saving
                  ? null
                  : () async {
                if (!_formKey.currentState!.validate()) return;
                setState(() => _saving = true);
                final updated = profile.copyWith(
                  name: _name.text.trim(),
                  phone: _phone.text.trim(),
                );
                if (!mounted) return;
                setState(() => _saving = false);
                Navigator.of(context).pop<UserProfile>(updated);
              },
              child: Text(_saving ? 'Saving...' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}
