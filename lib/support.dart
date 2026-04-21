import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_colors.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({Key? key}) : super(key: key);

  // Email launcher
  void _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@ayuscan.com', // <-- change to your email
      query: 'subject=Customer Support Request&body=Hello AyuScan Team,',
    );
    await launchUrl(emailLaunchUri);
  }

  // WhatsApp launcher
  void _launchWhatsApp() async {
    const phoneNumber = '+911234567890'; // <-- change to your WhatsApp number
    final Uri whatsappUri = Uri.parse('https://wa.me/$phoneNumber?text=Hello, I need support with AyuScan app.');
    await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Support'),
        backgroundColor: AppColors.darkGreen,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.support_agent, size: 80, color: AppColors.darkGreen),
            const SizedBox(height: 20),
            const Text(
              'Need Help?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Our support team is here to assist you. Choose your preferred way to contact us:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _launchEmail,
              icon: const Icon(Icons.email),
              label: const Text('Email Support'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mediumGreen,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _launchWhatsApp,
              icon: const Icon(Icons.chat),
              label: const Text('WhatsApp Support'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
