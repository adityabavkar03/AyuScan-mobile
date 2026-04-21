import 'package:flutter/material.dart';
import 'login.dart' as login;
import 'Ayubot.dart';
import 'app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pulse.dart';
import 'yoga.dart';
import 'support.dart';
import 'dosha_result.dart';
import 'ayuscan_api_service.dart';
import 'health_questions.dart'; // ← NEW: Health questionnaire

// ------------------ DASHBOARD PAGE ------------------ //
class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String userName = "User";
  String userEmail = "";

  int? latestPulse;
  String? predictedDosha;
  double? confidence;
  Map<String, dynamic>? doshaResult;
  bool _isLoading = false;
  bool _backendOnline = false;

  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _checkBackend();
  }

  void _loadUserInfo() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userEmail = user.email ?? '';
        userName = user.displayName ?? user.email?.split('@')[0] ?? 'User';
      });
    }
  }

  Future<void> _checkBackend() async {
    final online = await AyuScanApiService.isOnline();
    setState(() => _backendOnline = online);
  }

  // ── NEW: Opens health questionnaire, then pulse detection, then predicts Dosha
  Future<void> _detectPulse() async {
    // Step 1: Collect health data from questionnaire
    final healthData = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HealthQuestionsPage()),
    );

    if (healthData != null) {
      // Step 2: Health data received, update pulse
      setState(() {
        latestPulse = healthData['bpm'];
        _isLoading = true;
      });

      // Step 3: Calculate pulse features from BPM
      final double bpm = healthData['bpm'].toDouble();
      final int pulseSpeed = bpm < 65 ? 0 : (bpm <= 85 ? 1 : 2);
      final int pulseRhythm = bpm < 65 ? 2 : (bpm <= 85 ? 1 : 0);
      final int strength = bpm < 65 ? 2 : (bpm <= 85 ? 1 : 1);

      // Step 4: Send ALL 10 features to AI backend
      await _predictDoshaWithAllFeatures(
        bpm: bpm,
        pulseRhythm: pulseRhythm,
        pulseStrength: strength,
        pulseSpeed: pulseSpeed,
        skinType: healthData['skin_type'],
        bodyTemp: healthData['body_temp'],
        sleepQuality: healthData['sleep_quality'],
        digestion: healthData['digestion'],
        stressLevel: healthData['stress_level'],
        age: healthData['age'],
      );
    }
  }

  // ── Sends ALL health features to Python backend for Dosha prediction
  Future<void> _predictDoshaWithAllFeatures({
    required double bpm,
    required int pulseRhythm,
    required int pulseStrength,
    required int pulseSpeed,
    required int skinType,
    required double bodyTemp,
    required int sleepQuality,
    required int digestion,
    required int stressLevel,
    required int age,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final result = await AyuScanApiService.predictDosha(
      uid: user.uid,
      bpm: bpm,
      pulseRhythm: pulseRhythm,
      pulseStrength: pulseStrength,
      pulseSpeed: pulseSpeed,
      skinType: skinType,
      bodyTemp: bodyTemp,
      sleepQuality: sleepQuality,
      digestion: digestion,
      stressLevel: stressLevel,
      age: age,
    );

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      setState(() {
        predictedDosha = result['predicted_dosha'];
        confidence = result['confidence']?.toDouble();
        doshaResult = result;
        _history.insert(0, {
          'date': DateTime.now().toString().split(' ')[0],
          'pulse': latestPulse,
          'dosha': predictedDosha,
          'conf': confidence,
        });
      });

      // Navigate to Dosha Result screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DoshaResultPage(result: result),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ ${result['error'] ?? 'Prediction failed'}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => login.LoginPage()),
          (route) => false,
    );
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(name: userName, email: userEmail),
      ),
    ).then((result) {
      if (result != null) {
        setState(() {
          userName = result['name'];
          userEmail = result['email'];
        });
      }
    });
  }

  Color _doshaColor(String? dosha) {
    switch (dosha) {
      case 'Vata':
        return const Color(0xFF8B7CF6);
      case 'Pitta':
        return const Color(0xFFF97316);
      case 'Kapha':
        return const Color(0xFF22C55E);
      default:
        return AppColors.lightGreen;
    }
  }

  String _doshaEmoji(String? dosha) {
    switch (dosha) {
      case 'Vata':
        return '🌬️';
      case 'Pitta':
        return '🔥';
      case 'Kapha':
        return '🌿';
      default:
        return '💚';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      appBar: AppBar(
        title: const Text("AyuScan Dashboard"),
        backgroundColor: AppColors.darkGreen,
        actions: [
          // Backend status indicator
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(
              Icons.circle,
              color: _backendOnline ? Colors.greenAccent : Colors.red,
              size: 14,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: AppColors.white),
            tooltip: "AyuBot",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ChatPage()),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Welcome card
            _buildWelcomeCard(),
            const SizedBox(height: 16),

            // ── Latest result card
            _buildResultCard(),
            const SizedBox(height: 16),

            // ── Scan button
            Center(child: _buildScanButton()),
            const SizedBox(height: 24),

            // ── History header
            Text(
              "Scan History",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGreen,
              ),
            ),
            const SizedBox(height: 8),

            // ── History list
            Expanded(child: _buildHistory()),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.white,
            radius: 28,
            child: Icon(Icons.person, color: AppColors.darkGreen, size: 32),
          ),
          const SizedBox(width: 14),
          Expanded(                  // ← ADD THIS
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome, $userName 👋",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,  // ← safety net for long names
                ),
                const SizedBox(height: 4),
                Text(
                  _backendOnline ? "AI Backend: Online ✅" : "AI Backend: Offline ⚠️",
                  style: TextStyle(
                    color: _backendOnline ? Colors.greenAccent : Colors.orangeAccent,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: predictedDosha != null
          ? _doshaColor(predictedDosha).withOpacity(0.15)
          : AppColors.lightGreen,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text("Analyzing your pulse with AI..."),
            ],
          ),
        )
            : predictedDosha == null
            ? const Row(
          children: [
            Icon(Icons.favorite_border, color: AppColors.darkGreen),
            SizedBox(width: 10),
            Text(
              "Tap 'Start Scan' to detect your Dosha",
              style: TextStyle(fontSize: 16),
            ),
          ],
        )
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _doshaEmoji(predictedDosha),
                  style: const TextStyle(fontSize: 36),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Your Dosha: $predictedDosha",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _doshaColor(predictedDosha),
                      ),
                    ),
                    Text(
                      "Pulse: $latestPulse BPM  •  Confidence: ${confidence?.toStringAsFixed(1)}%",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () {
                if (doshaResult != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DoshaResultPage(result: doshaResult!),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text("View Full Recommendations"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanButton() {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _detectPulse,
      icon: const Icon(Icons.favorite, color: AppColors.white),
      label: Text(
        _isLoading ? "Analyzing..." : "Start Scan",
        style: const TextStyle(fontSize: 18, color: AppColors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.mediumGreen,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildHistory() {
    if (_history.isEmpty) {
      return Center(
        child: Text(
          "No scans yet. Start your first scan!",
          style: TextStyle(color: Colors.grey[500]),
        ),
      );
    }
    return ListView.builder(
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final item = _history[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Text(
              _doshaEmoji(item['dosha']),
              style: const TextStyle(fontSize: 28),
            ),
            title: Text(
              "${item['dosha']} Dosha",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _doshaColor(item['dosha']),
              ),
            ),
            subtitle: Text("Pulse: ${item['pulse']} BPM"),
            trailing: Text(
              item['date'],
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(userName),
            accountEmail: Text(userEmail),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: AppColors.white,
              child: Icon(Icons.person, color: AppColors.darkGreen, size: 40),
            ),
            decoration: const BoxDecoration(color: AppColors.darkGreen),
          ),
          ListTile(
            leading: const Icon(Icons.person, color: AppColors.darkGreen),
            title: const Text("Profile"),
            onTap: _openProfile,
          ),
          ListTile(
            leading: const Icon(Icons.self_improvement, color: AppColors.darkGreen),
            title: const Text("Yoga & Wellness"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => YogaPage()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.chat, color: AppColors.darkGreen),
            title: const Text("AyuBot"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ChatPage()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: AppColors.darkGreen),
            title: const Text("Settings"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingsPage()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.support_agent, color: AppColors.darkGreen),
            title: const Text("Support"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SupportPage()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout", style: TextStyle(color: Colors.red)),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}

// ------------------ PROFILE PAGE ------------------ //
class ProfilePage extends StatefulWidget {
  final String name;
  final String email;
  ProfilePage({required this.name, required this.email});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  String _gender = 'Male';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _emailController = TextEditingController(text: widget.email);
  }

  void _saveProfile() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }
    Navigator.pop(context, {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'age': _ageController.text.trim(),
      'height': _heightController.text.trim(),
      'weight': _weightController.text.trim(),
      'gender': _gender,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile saved!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: AppColors.darkGreen,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 60,
              backgroundColor: AppColors.lightGreen,
              child: Icon(Icons.person, size: 80, color: AppColors.darkGreen),
            ),
            const SizedBox(height: 20),
            _field("Name", _nameController),
            const SizedBox(height: 15),
            _field("Email", _emailController, type: TextInputType.emailAddress),
            const SizedBox(height: 15),
            _field("Age", _ageController, type: TextInputType.number),
            const SizedBox(height: 15),
            _field("Height (cm)", _heightController, type: TextInputType.number),
            const SizedBox(height: 15),
            _field("Weight (kg)", _weightController, type: TextInputType.number),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: _gender,
              items: ['Male', 'Female', 'Other']
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (val) => setState(() => _gender = val!),
              decoration: const InputDecoration(
                labelText: "Gender",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mediumGreen,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text("Save",
                  style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

// ------------------ SETTINGS PAGE ------------------ //
class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: AppColors.darkGreen,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text("Notifications"),
            value: _notifications,
            onChanged: (val) => setState(() => _notifications = val),
            secondary: const Icon(Icons.notifications, color: AppColors.darkGreen),
          ),
          ListTile(
            leading: const Icon(Icons.info, color: AppColors.darkGreen),
            title: const Text("About AyuScan"),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: "AyuScan",
                applicationVersion: "1.0.0",
                applicationIcon: const Icon(
                  Icons.favorite,
                  color: AppColors.darkGreen,
                  size: 40,
                ),
                children: [
                  const Text(
                    "AyuScan uses AI to predict your Ayurvedic Dosha type from pulse analysis.",
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}