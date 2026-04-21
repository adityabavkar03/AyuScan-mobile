import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'pulse.dart';

class HealthQuestionsPage extends StatefulWidget {
  const HealthQuestionsPage({super.key});

  @override
  _HealthQuestionsPageState createState() => _HealthQuestionsPageState();
}

class _HealthQuestionsPageState extends State<HealthQuestionsPage> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _bodyTempController = TextEditingController(text: '36.6');

  // Dropdown values
  int _skinType = 1; // 0=Dry, 1=Normal, 2=Oily
  int _digestion = 1; // 0=Poor, 1=Average, 2=Good

  // Ratings
  int _sleepQuality = 3; // 1-5
  int _stressLevel = 2; // 1-5

  @override
  void dispose() {
    _ageController.dispose();
    _bodyTempController.dispose();
    super.dispose();
  }

  void _proceedToPulseScan() {
    if (_formKey.currentState!.validate()) {
      // Navigate to pulse detection with health data
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PulsePage(),
        ),
      ).then((bpm) {
        if (bpm != null) {
          // Return all health data + BPM to dashboard
          Navigator.pop(context, {
            'bpm': bpm,
            'skin_type': _skinType,
            'body_temp': double.parse(_bodyTempController.text),
            'sleep_quality': _sleepQuality,
            'digestion': _digestion,
            'stress_level': _stressLevel,
            'age': int.parse(_ageController.text),
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Health Assessment"),
        backgroundColor: AppColors.darkGreen,
      ),
      backgroundColor: AppColors.creamBackground,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                "Answer a few questions for accurate Dosha analysis",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppColors.darkGreen,
                ),
              ),
              const SizedBox(height: 30),

              // Age
              _buildSectionTitle("Personal Information"),
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Age",
                  hintText: "Enter your age",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.person, color: AppColors.mediumGreen),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your age';
                  }
                  final age = int.tryParse(value);
                  if (age == null || age < 1 || age > 120) {
                    return 'Please enter a valid age';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Body Temperature
              TextFormField(
                controller: _bodyTempController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: "Body Temperature (°C)",
                  hintText: "Normal: 36.5-37.5",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.thermostat, color: AppColors.mediumGreen),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter body temperature';
                  }
                  final temp = double.tryParse(value);
                  if (temp == null || temp < 35 || temp > 42) {
                    return 'Please enter a valid temperature (35-42°C)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // Skin Type
              _buildSectionTitle("Physical Characteristics"),
              const Text(
                "Skin Type:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              _buildRadioGroup(
                value: _skinType,
                options: const ['Dry', 'Normal', 'Oily'],
                onChanged: (value) => setState(() => _skinType = value),
              ),
              const SizedBox(height: 25),

              // Digestion
              const Text(
                "Digestion:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              _buildRadioGroup(
                value: _digestion,
                options: const ['Poor', 'Average', 'Good'],
                onChanged: (value) => setState(() => _digestion = value),
              ),
              const SizedBox(height: 30),

              // Sleep Quality
              _buildSectionTitle("Lifestyle Factors"),
              const Text(
                "Sleep Quality:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              _buildRatingBar(
                value: _sleepQuality,
                onChanged: (value) => setState(() => _sleepQuality = value),
              ),
              const SizedBox(height: 25),

              // Stress Level
              const Text(
                "Stress Level:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              _buildRatingBar(
                value: _stressLevel,
                onChanged: (value) => setState(() => _stressLevel = value),
              ),
              const SizedBox(height: 40),

              // Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _proceedToPulseScan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mediumGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Continue to Pulse Scan",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.darkGreen,
        ),
      ),
    );
  }

  Widget _buildRadioGroup({
    required int value,
    required List<String> options,
    required Function(int) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: options.asMap().entries.map((entry) {
          return RadioListTile<int>(
            title: Text(entry.value),
            value: entry.key,
            groupValue: value,
            activeColor: AppColors.mediumGreen,
            onChanged: (val) => onChanged(val!),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRatingBar({
    required int value,
    required Function(int) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(5, (index) {
          final rating = index + 1;
          return GestureDetector(
            onTap: () => onChanged(rating),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: rating <= value
                    ? AppColors.mediumGreen
                    : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$rating',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: rating <= value ? Colors.white : Colors.grey[600],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}