// lib/screens/setup_admin_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SetupAdminScreen extends StatefulWidget {
  const SetupAdminScreen({Key? key}) : super(key: key);

  @override
  State<SetupAdminScreen> createState() => _SetupAdminScreenState();
}

class _SetupAdminScreenState extends State<SetupAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('First Admin Setup')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                'Create First Admin Account',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => v?.contains('@') == true ? null : 'Valid email required',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password (min 6 chars)'),
                obscureText: true,
                validator: (v) => (v?.length ?? 0) >= 6 ? null : 'Min 6 characters',
              ),
              const SizedBox(height: 24),
              if (_message != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  color: _message!.contains('Error') ? Colors.red[100] : Colors.green[100],
                  child: Text(_message!),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createAdmin,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Create Admin Account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createAdmin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      await authProvider.createAdminUser(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
      );

      setState(() {
        _message = '✅ Admin created successfully! You can now login.';
      });
    } catch (e) {
      setState(() {
        _message = '❌ Error: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }
}