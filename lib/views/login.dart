import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:battleships/views/gamelist.dart';

class LoginView extends StatefulWidget {
  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  bool _isLoginMode = true;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _message = '';

  static const String apiHostName = '165.227.117.48';

  Future<void> _login() async {
    final username = _usernameController.text;
    final password = _passwordController.text;

    final response = await http.post(
      Uri.http(apiHostName, '/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final String accessToken = data['access_token'];

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              GameListView(username: username, accessToken: accessToken),
        ),
      );
    } else {
      setState(() {
        _message = 'Invalid credentials. Please try again.';
      });
    }
  }

  Future<void> _register() async {
    final username = _usernameController.text;
    final password = _passwordController.text;

    final response = await http.post(
      Uri.http(apiHostName, '/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final String accessToken = data['access_token'];
      final String message = data['message'];

      setState(() {
        _message = '$message'; //\nAccess Token: $accessToken';
      });

      // Navigate to GameListView on successful registration
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              GameListView(username: username, accessToken: accessToken),
        ),
      );
    } else {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      if (responseData['error'] == "Username or password too short") {
        setState(() {
          _message = 'Username or password too short';
        });
      } else {
        setState(() {
          _message = 'Invalid credentials. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoginMode ? 'Login' : 'Register'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                if (_isLoginMode) {
                  await _login();
                } else {
                  await _register();
                }
              },
              child: Text(_isLoginMode ? 'Login' : 'Register'),
            ),
            SizedBox(height: 16),
            Text(
              _message,
              style: TextStyle(
                  color: _message.contains('successful')
                      ? Colors.green
                      : Colors.red),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _message = '';
                  _usernameController.text = '';
                  _passwordController.text = '';
                  _isLoginMode = !_isLoginMode;
                });
              },
              child: Text(_isLoginMode
                  ? 'New User? Register here'
                  : 'Already have an account? Login'),
            ),
          ],
        ),
      ),
    );
  }
}
