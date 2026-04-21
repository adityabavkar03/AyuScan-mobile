import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';

class YogaPage extends StatefulWidget {
  @override
  _YogaPageState createState() => _YogaPageState();
}

class _YogaPageState extends State<YogaPage> {
  String selectedCategory = 'All';

  final List<Map<String, dynamic>> yogaList = [
    {
      "name": "Surya Namaskar",
      "category": "Flexibility",
      "description":
          "A series of 12 poses that energize the body, improve flexibility, and promote better digestion.",
      "image":
          "https://media.istockphoto.com/id/1076946698/photo/young-sporty-woman-practicing-yoga-doing-upward-facing-dog-exercise.jpg?s=612x612&w=0&k=20&c=l93Nl8oY0Kg2IaXCJ1hMTw0rlI8Dg9fQqtvPT1Vgf5w=",
    },
    {
      "name": "Vrikshasana (Tree Pose)",
      "category": "Balance",
      "description":
          "Enhances stability, focus, and strengthens legs and back.",
      "image":
          "https://media.istockphoto.com/id/514717606/photo/woman-in-yoga-vrikshasana-tree-pose-outdoors.jpg?s=612x612&w=0&k=20&c=B6vMSxaaZ7wuD71RFdhLgZYe-JMq6dnjhVOm67uWERk=",
    },
    {
      "name": "Bhujangasana (Cobra Pose)",
      "category": "Stress Relief",
      "description":
          "Opens up the chest, strengthens the spine, and reduces tension in the back.",
      "image":
          "https://media.istockphoto.com/id/924163406/photo/young-woman-doing-cobra-exercise.jpg?s=612x612&w=0&k=20&c=h9nNF3H0eYGIZMTTPy1aGuU8_grk0Hc_caQEU93CU2Y=",
    },
    {
      "name": "Padmasana (Lotus Pose)",
      "category": "Meditation",
      "description":
          "Improves posture, calms the mind, and deepens meditation.",
      "image":
          "https://www.shutterstock.com/image-photo/young-woman-practicing-lotus-asana-260nw-1909519561.jpg",
    },
    {
      "name": "Trikonasana (Triangle Pose)",
      "category": "Flexibility",
      "description":
          "Stretches the body, improves digestion, and strengthens thighs and knees.",
      "image":
          "https://cdn.prod.website-files.com/683b218dcc58f93d54ce8e1d/68ad866a5ebbd9902be26016_trikonasana-triangle-pose.webp",
    },
    {
      "name": "Balasana (Child’s Pose)",
      "category": "Stress Relief",
      "description":
          "A relaxing pose that calms the mind and relieves tension in the spine.",
      "image":
          "https://www.shutterstock.com/image-photo/side-view-asian-woman-wearing-600nw-2052531170.jpg",
    },
    {
      "name": "Navasana (Boat Pose)",
      "category": "Weight Loss",
      "description": "Builds core strength and tones abdominal muscles.",
      "image":
          "https://media.istockphoto.com/id/1180509403/photo/young-woman-practicing-yoga-doing-paripurna-navasana-exercise.jpg?s=612x612&w=0&k=20&c=AKQloT-e2gaB_4sZzB1VKYwVFUONfjxQKTwZKdj8JFU=",
    },
  ];

  final List<String> categories = [
    'All',
    'Flexibility',
    'Balance',
    'Stress Relief',
    'Meditation',
    'Weight Loss',
  ];

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredYogaList = selectedCategory == 'All'
        ? yogaList
        : yogaList
              .where((yoga) => yoga["category"] == selectedCategory)
              .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("Yoga & Wellness"),
        backgroundColor: AppColors.darkGreen,
      ),
      body: Column(
        children: [
          // Category selector
          Container(
            height: 60,
            color: AppColors.lightGreen.withOpacity(0.3),
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                String category = categories[index];
                bool isSelected = category == selectedCategory;

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                  child: ChoiceChip(
                    label: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.darkGreen,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.darkGreen,
                    onSelected: (selected) {
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                    backgroundColor: Colors.white,
                    elevation: 3,
                  ),
                );
              },
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: filteredYogaList.length,
              itemBuilder: (context, index) {
                final yoga = filteredYogaList[index];
                return Card(
                  elevation: 4,
                  margin: EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: yoga["image"],
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 180,
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.darkGreen,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 180,
                            color: Colors.grey[300],
                            child: Icon(
                              Icons.broken_image,
                              size: 60,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.self_improvement,
                                  color: AppColors.darkGreen,
                                  size: 22,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  yoga["name"]!,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.darkGreen,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6),
                            Text(
                              "Category: ${yoga["category"]}",
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              yoga["description"]!,
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
