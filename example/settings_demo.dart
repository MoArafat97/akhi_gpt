import 'package:flutter/material.dart';
import '../lib/pages/settings_page.dart';

void main() {
  runApp(SettingsDemo());
}

class SettingsDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Settings Demo',
      theme: ThemeData(
        primarySwatch: Colors.brown,
      ),
      home: SettingsDemoHome(),
    );
  }
}

class SettingsDemoHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings Demo'),
        backgroundColor: Color(0xFFB7AFA3),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Akhi GPT Settings Demo',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'This demo shows the comprehensive settings page\nwith all user-tunable options for the app.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFB7AFA3),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: Text(
                'Open Settings',
                style: TextStyle(fontSize: 18),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Features:\n'
              '• Chat settings (streaming, daily limits)\n'
              '• Model & privacy controls\n'
              '• Journal preferences\n'
              '• Mood & Duʿāʾ options\n'
              '• Analytics toggles\n'
              '• Safety settings\n'
              '• Appearance themes\n'
              '• Secure API key storage\n'
              '• Environment switching\n'
              '• All data stored locally',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
