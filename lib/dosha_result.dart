import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'yoga.dart';

class DoshaResultPage extends StatelessWidget {
  final Map<String, dynamic> result;
  const DoshaResultPage({required this.result});

  Color get _doshaColor {
    switch (result['predicted_dosha']) {
      case 'Vata':  return const Color(0xFF8B7CF6);
      case 'Pitta': return const Color(0xFFF97316);
      case 'Kapha': return const Color(0xFF22C55E);
      default:      return AppColors.darkGreen;
    }
  }

  String get _doshaEmoji {
    switch (result['predicted_dosha']) {
      case 'Vata':  return '🌬️';
      case 'Pitta': return '🔥';
      case 'Kapha': return '🌿';
      default:      return '💚';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dosha      = result['predicted_dosha'] ?? 'Unknown';
    final confidence = result['confidence'] ?? 0.0;
    final summary    = result['summary'] as Map<String, dynamic>? ?? {};
    final probs      = result['probabilities'] as Map<String, dynamic>? ?? {};

    final topFoods   = List<String>.from(summary['top_foods'] ?? []);
    final avoidFoods = List<String>.from(summary['avoid_foods'] ?? []);
    final topYoga    = List<String>.from(summary['top_yoga'] ?? []);
    final topTips    = List<String>.from(summary['top_tips'] ?? []);
    final herbs      = List<String>.from(summary['herbs'] ?? []);
    final description = summary['description'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      appBar: AppBar(
        title: const Text("Your Dosha Result"),
        backgroundColor: AppColors.darkGreen,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Main Dosha Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _doshaColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(_doshaEmoji, style: const TextStyle(fontSize: 60)),
                  const SizedBox(height: 8),
                  Text(
                    "$dosha Dosha",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Confidence: ${confidence.toStringAsFixed(1)}%",
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Probability Bar Chart
            _buildSection(
              title: "Dosha Analysis",
              icon: Icons.bar_chart,
              child: Column(
                children: probs.entries.map((e) {
                  final pct = (e.value as num).toDouble();
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 60,
                          child: Text(
                            e.key,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: pct / 100,
                              minHeight: 14,
                              backgroundColor: Colors.grey[200],
                              color: _doshaColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text("${pct.toStringAsFixed(1)}%"),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // ── Description
            _buildSection(
              title: "About Your Dosha",
              icon: Icons.info_outline,
              child: Text(description, style: const TextStyle(fontSize: 15, height: 1.5)),
            ),
            const SizedBox(height: 12),

            // ── Recommended Foods
            _buildSection(
              title: "🥗 Recommended Foods",
              icon: Icons.restaurant,
              child: _buildList(topFoods, Colors.green),
            ),
            const SizedBox(height: 12),

            // ── Foods to Avoid
            _buildSection(
              title: "🚫 Foods to Avoid",
              icon: Icons.no_food,
              child: _buildList(avoidFoods, Colors.red),
            ),
            const SizedBox(height: 12),

            // ── Yoga
            _buildSection(
              title: "🧘 Yoga Recommendations",
              icon: Icons.self_improvement,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildList(topYoga, AppColors.darkGreen),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => YogaPage()),
                    ),
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text("View Yoga Poses"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mediumGreen,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Lifestyle Tips
            _buildSection(
              title: "💡 Lifestyle Tips",
              icon: Icons.lightbulb_outline,
              child: _buildList(topTips, Colors.orange),
            ),
            const SizedBox(height: 12),

            // ── Herbs
            _buildSection(
              title: "🌿 Recommended Herbs",
              icon: Icons.eco,
              child: _buildList(herbs, Colors.teal),
            ),
            const SizedBox(height: 20),

            // ── Disclaimer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.amber),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "This is AI-based guidance only. Please consult an Ayurvedic practitioner for professional advice.",
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.darkGreen),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGreen,
                  ),
                ),
              ],
            ),
            const Divider(),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<String> items, Color dotColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 7),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(item, style: const TextStyle(fontSize: 15))),
            ],
          ),
        );
      }).toList(),
    );
  }
}
