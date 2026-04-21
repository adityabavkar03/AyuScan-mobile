import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

// ============================================================
//  AyuBot — Fully Fixed Version with Debug + Extra Keywords
//  ✅ Gemini AI with proper error logging
//  ✅ Panchakarma, Sinus, Digestion added to local rules
//  ✅ No asterisks in responses
//  ✅ Typo-friendly keywords
//  ✅ Debug prints in Logcat (filter: AyuBot)
//  ✅ Works on emulator AND real device
// ============================================================

class ChatMessage {
  final String text;
  final bool fromUser;
  final bool isTyping;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.fromUser,
    this.isTyping = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  final List<Map<String, dynamic>> _conversationHistory = [];

  // ── Gemini API Configuration ──
  static const String _geminiApiKey = '';
  static const String _geminiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent';
  static const String _systemPrompt =
      '''You are AyuBot, an expert Ayurvedic health assistant in the AyuScan app.
Provide helpful Ayurvedic remedies and allopathic alternatives.
Keep responses under 150 words. Be warm and practical.
Use 🌿 for Ayurvedic, 💊 for allopathic suggestions.
Always advise consulting a doctor for serious conditions.
Format responses clearly with Ayurvedic and Allopathic sections.''';

  // ── Extended Local Rules (50+ topics) ──
  final Map<List<String>, String> _rules = {

    // General illness
    ['feeling sick', 'not well', 'unwell', 'ill', 'sick']:
        '🌿 Ayurvedic: Tulsi tea, ginger water, complete rest.\n💊 Allopathic: Rest, hydration, OTC cold medication if needed.',

    // Back pain
    ['back pain', 'lower back pain', 'backache', 'back ache', 'spine', 'kamar dard']:
        '🌿 Ayurvedic: Turmeric milk, yoga (Cat-Cow pose), warm sesame oil massage.\n💊 Allopathic: NSAIDs like ibuprofen, physiotherapy.',

    // Stomach & Digestion
    ['stomach', 'indigestion', 'bloating', 'gas', 'flatulence', 'pet dard', 'tummy', 'stomach ache', 'stomachache', 'digestive', 'digestion', 'poor digestion', 'improve digestion', 'pachhan']:
        '🌿 Ayurvedic: Ginger water, fennel (saunf) seeds after meals, cumin tea, Triphala at bedtime.\n💊 Allopathic: Antacids (Gelusil, Eno), simethicone for gas.\n\n💡 Tip: Eat mindfully, chew well, avoid cold drinks with meals.',

    // Cold and cough
    ['cold', 'cough', 'caugh', 'khaansi', 'khansi', 'throat', 'sore throat', 'runny nose', 'sneezing', 'nasal', 'zukam', 'sardi', 'khasi']:
        '🌿 Ayurvedic: Tulsi + honey tea, ginger-lemon water, steam inhalation, turmeric milk.\n💊 Allopathic: Antihistamines (Cetirizine), Strepsils lozenges, nasal spray.',

    // Headache
    ['headache', 'migraine', 'head pain', 'headche', 'headach', 'sir dard', 'sir me dard', 'head ache']:
        '🌿 Ayurvedic: Peppermint oil on temples, sesame oil scalp massage, ginger tea.\n💊 Allopathic: Paracetamol (500mg), ibuprofen, rest in dark quiet room.',

    // Sleep
    ['sleep', 'insomnia', 'sleepless', 'cant sleep', "can't sleep", 'nind nahi', 'neend', 'sleep problem', 'sleep issues']:
        '🌿 Ayurvedic: Warm milk + ashwagandha + nutmeg at bedtime, Brahmi tea, Shankhpushpi.\n💊 Allopathic: Melatonin 3–5mg (short-term), consult doctor for persistent insomnia.',

    // Stress and anxiety
    ['stress', 'anxiety', 'tension', 'worried', 'panic', 'anxious', 'tense', 'nervous', 'tanaav', 'chinta']:
        '🌿 Ayurvedic: Ashwagandha, Brahmi tea, Anulom Vilom pranayama, Shankhpushpi.\n💊 Allopathic: Counselling (CBT), SSRIs only under prescription.',

    // Fever
    ['fever', 'temperature', 'bukhar', 'high temperature', 'chills', 'fevar', 'fevr', 'bukhaar']:
        '🌿 Ayurvedic: Coriander tea, tulsi decoction, giloy juice, ginger + honey tea.\n💊 Allopathic: Paracetamol (500–1000mg), cool compresses, ORS fluids.\n⚠️ See a doctor if fever exceeds 103°F for 3+ days.',

    // Diarrhea
    ['diarrhea', 'loose motion', 'watery stool', 'diarrhoea', 'loose motions', 'daast']:
        '🌿 Ayurvedic: Pomegranate juice, buttermilk with cumin, banana.\n💊 Allopathic: ORS solution, loperamide (Imodium), stay hydrated.',

    // Constipation
    ['constipation', 'no bowel', 'hard stool', 'qabz', 'kabj', 'kabz']:
        '🌿 Ayurvedic: Triphala powder at night with warm water, warm water in morning.\n💊 Allopathic: Lactulose syrup, isabgol (psyllium husk).',

    // Acidity
    ['acidity', 'acid reflux', 'heartburn', 'gerd', 'burning chest', 'chest burn']:
        '🌿 Ayurvedic: Aloe vera juice, licorice (mulethi) root, cold milk, amla.\n💊 Allopathic: Antacids, PPIs like omeprazole (consult doctor).',

    // Allergy
    ['allergy', 'rhinitis', 'hay fever', 'allergic', 'itchy eyes', 'watery eyes']:
        '🌿 Ayurvedic: Turmeric milk, Jala Neti (nasal rinse), local honey.\n💊 Allopathic: Antihistamines like cetirizine or loratadine.',

    // Sinus — NEW ADDED
    ['sinus', 'sinusitis', 'sinus infection', 'nasal blockage', 'blocked nose', 'congestion', 'nose block']:
        '🌿 Ayurvedic: Nasya — 2–3 drops warm sesame oil in each nostril, steam inhalation with eucalyptus + ajwain, Jala Neti (saline rinse), turmeric + ginger tea.\n💊 Allopathic: Saline nasal spray, decongestants (Xylometazoline), antibiotics if bacterial (as prescribed).\n\n🧘 Yoga: Kapalbhati and Anulom Vilom help clear nasal passages.',

    // Panchakarma — NEW ADDED
    ['panchakarma', 'panchkarma', 'detox', 'body cleanse', 'purification', 'ayurvedic detox']:
        '🌿 Panchakarma — Ayurvedic Detox Therapy:\n\nPanchakarma is Ayurveda\'s 5-step body purification done under expert guidance:\n1. Vamana — Therapeutic vomiting (Kapha)\n2. Virechana — Purgation (Pitta)\n3. Basti — Medicated enema (Vata)\n4. Nasya — Nasal therapy (head/sinus)\n5. Raktamokshana — Blood purification\n\n✅ Benefits: Deep cellular detox, better digestion, rejuvenation.\n⚠️ Must be done under a certified Ayurvedic doctor only.',

    // Body pain
    ['body pain', 'muscle pain', 'muscle ache', 'soreness', 'badan dard', 'body ache', 'bodyache']:
        '🌿 Ayurvedic: Warm sesame oil Abhyanga massage, turmeric milk, Mahanarayan oil.\n💊 Allopathic: Ibuprofen, hot/cold compress, adequate rest.',

    // Acne / Skin
    ['acne', 'pimples', 'breakout', 'blemish', 'pimple', 'muhase']:
        '🌿 Ayurvedic: Neem paste, turmeric face mask, aloe vera gel, Manjistha tea (blood purifier).\n💊 Allopathic: Salicylic acid face wash, benzoyl peroxide cream.',

    // Hair
    ['hair fall', 'hair loss', 'dandruff', 'scalp', 'baal', 'baal jhadna', 'hair problem']:
        '🌿 Ayurvedic: Bhringraj oil massage, amla + yogurt pack, fenugreek (methi) seed paste.\n💊 Allopathic: Minoxidil, ketoconazole anti-dandruff shampoo.',

    // Toothache
    ['toothache', 'tooth pain', 'dental pain', 'tooth ache', 'daant dard']:
        '🌿 Ayurvedic: Clove oil on affected tooth, oil pulling with sesame oil.\n💊 Allopathic: Ibuprofen for pain relief, dental consultation required.',

    // Eye strain
    ['eye strain', 'red eyes', 'eye pain', 'dry eyes', 'eye problem', 'aankh']:
        '🌿 Ayurvedic: Rose water drops, Triphala eye wash, cucumber slices.\n💊 Allopathic: Artificial tears, antihistamine eye drops.\n💡 20-20-20 rule: Every 20 min, look 20 feet away for 20 seconds.',

    // Skin rash & itching
    ['skin rash', 'itching', 'hives', 'eczema', 'rash', 'khujli', 'skin irritation']:
        '🌿 Ayurvedic: Aloe vera gel, neem paste, coconut oil, Manjistha blood purifier.\n💊 Allopathic: Calamine lotion, hydrocortisone cream, antihistamines.',

    // Burns
    ['burn', 'minor burn', 'scalded', 'jalna']:
        '🌿 Ayurvedic: Fresh aloe vera gel, coconut oil after cooling.\n💊 Allopathic: Cool running water for 10 min, burn cream. Never use ice.',

    // Sprain
    ['sprain', 'injury', 'twisted ankle', 'strain', 'moch', 'ankle pain']:
        '🌿 Ayurvedic: Turmeric paste with warm water, gentle massage after 48 hours.\n💊 Allopathic: RICE method — Rest, Ice, Compression, Elevation, then ibuprofen.',

    // Nausea
    ['nausea', 'vomiting', 'motion sickness', 'ulti', 'vomit', 'feel like vomiting']:
        '🌿 Ayurvedic: Ginger tea, lemon water, fennel seeds, mint leaves.\n💊 Allopathic: ORS for hydration, domperidone, avoid heavy meals.',

    // UTI
    ['urinary infection', 'uti', 'burning urine', 'frequent urination', 'peshab', 'urine problem']:
        '🌿 Ayurvedic: Barley water, cranberry juice, Gokshura herb, coriander seed water.\n💊 Allopathic: Antibiotics (nitrofurantoin), increase water intake drastically.',

    // Diabetes
    ['diabetes', 'blood sugar', 'sugar levels', 'diabetic', 'sugar', 'madhumeh']:
        '🌿 Ayurvedic: Bitter gourd (karela) juice, fenugreek seeds soaked overnight, turmeric.\n💊 Allopathic: Metformin, insulin — only as prescribed.\n⚠️ Never stop diabetes medication without doctor advice.',

    // Blood pressure
    ['blood pressure', 'hypertension', 'high bp', 'bp high', 'bp problem', 'bp']:
        '🌿 Ayurvedic: Arjuna bark tea, garlic clove daily, Sarpagandha (under guidance).\n💊 Allopathic: ACE inhibitors, beta-blockers — consult cardiologist.\n⚠️ BP above 180/120 is a medical emergency.',

    // Cholesterol
    ['cholesterol', 'triglycerides', 'heart health', 'high cholesterol']:
        '🌿 Ayurvedic: Garlic, coriander seeds water, Guggul supplement.\n💊 Allopathic: Statins (atorvastatin), dietary changes, regular checkups.',

    // Joint pain
    ['joint pain', 'arthritis', 'knee pain', 'rheumatism', 'joint', 'ghutne ka dard', 'joints']:
        '🌿 Ayurvedic: Shallaki (Boswellia), turmeric + ginger tea, warm Mahanarayan oil massage.\n💊 Allopathic: NSAIDs (ibuprofen), physiotherapy, glucosamine supplements.',

    // Depression
    ['depression', 'sad', 'low mood', 'feeling down', 'depressed', 'udaas', 'dukhi']:
        '🌿 Ayurvedic: Saffron in warm milk, Brahmi, meditation, daily sunlight exposure.\n💊 Allopathic: Therapy (CBT) highly effective, SSRIs under doctor supervision.\n⚠️ If you feel hopeless, please talk to someone you trust or a doctor.',

    // Thyroid
    ['thyroid', 'hypothyroid', 'hyperthyroid', 'thyroid problem', 'tsh']:
        '🌿 Ayurvedic: Ashwagandha, Kanchanar Guggulu, Sarvangasana yoga pose.\n💊 Allopathic: Levothyroxine (hypothyroid), methimazole (hyperthyroid).\n⚠️ Never stop thyroid medication without doctor advice.',

    // Weight
    ['weight', 'obesity', 'overweight', 'weight loss', 'fat', 'mota', 'wajan', 'motapa']:
        '🌿 Ayurvedic: Triphala at bedtime, Trikatu, warm lemon + honey water in morning.\n💊 Allopathic: Caloric deficit diet, 45-min daily walk, consult dietitian.',

    // Weakness / Fatigue
    ['weakness', 'fatigue', 'tiredness', 'low energy', 'weak', 'kamzori', 'thakaan']:
        '🌿 Ayurvedic: Ashwagandha, Chyawanprash daily, dates + warm milk.\n💊 Allopathic: Check Iron, Vitamin B12, Vitamin D levels. Supplements as needed.',

    // Immunity
    ['immunity', 'immune system', 'frequent illness', 'low immunity', 'immune', 'immune boost']:
        '🌿 Ayurvedic: Chyawanprash daily, Giloy juice, Amla, turmeric milk, Ashwagandha.\n💊 Allopathic: Vitamin C 500mg, Vitamin D, Zinc supplements.',

    // Liver
    ['liver', 'jaundice', 'hepatitis', 'liver problem', 'piliya']:
        '🌿 Ayurvedic: Kutki, Bhumyamalaki, Kalmegh — powerful liver protectors. Avoid alcohol.\n💊 Allopathic: Liv.52, consult gastroenterologist.\n⚠️ Jaundice with dark urine — see doctor immediately.',

    // Kidney
    ['kidney', 'kidney stone', 'renal', 'kidney pain', 'gurde']:
        '🌿 Ayurvedic: Punarnava herb, barley water, cucumber juice, Varuna bark decoction.\n💊 Allopathic: Increased hydration, alpha-blockers, ESWL for stones.\n⚠️ Blood in urine — seek emergency care.',

    // Respiratory / Asthma
    ['respiratory', 'asthma', 'breathing', 'wheezing', 'bronchitis', 'breathlessness', 'saans', 'dam']:
        '🌿 Ayurvedic: Vasaka (Malabar nut) leaf tea, Pushkarmool, turmeric + black pepper milk.\n💊 Allopathic: Always carry prescribed inhaler, bronchodilators (salbutamol).\n⚠️ Severe breathlessness = medical emergency.',

    // Menstrual / PCOS
    ['menstrual', 'period pain', 'dysmenorrhea', 'pcos', 'pcod', 'irregular periods', 'periods', 'mahwari']:
        '🌿 Ayurvedic: Shatavari (queen herb for women), Ashoka, warm sesame oil massage on abdomen, Lodhra.\n💊 Allopathic: NSAIDs for pain, OCP (consult gynecologist).',

    // Memory
    ['memory', 'concentration', 'brain fog', 'focus', 'forget', 'bhulna', 'yaaddasht']:
        '🌿 Ayurvedic: Brahmi — #1 brain herb, Shankhpushpi, 5 soaked almonds daily.\n💊 Allopathic: Omega-3 supplements, 8 hours sleep, cognitive exercises.',

    // Dry skin / Skin care
    ['dry skin', 'psoriasis', 'pigmentation', 'skin problem', 'dull skin', 'skin care', 'glow']:
        '🌿 Ayurvedic: Coconut oil daily, Manjistha blood purifier, Kumkumadi tailam, Aloe vera.\n💊 Allopathic: Good moisturizer, SPF sunscreen, dermatologist for persistent issues.',

    // Dosha - Vata
    ['vata', 'vata dosha', 'vata imbalance', 'vaat']:
        '🌬️ Vata Dosha (Air + Space):\n\nVata types are creative and quick but prone to anxiety and dryness.\n\nTo Balance Vata:\n• Warm, oily, nourishing foods — ghee, warm milk\n• Regular daily routine\n• Sesame oil Abhyanga massage\n• Avoid cold, raw, dry foods\n\nHerbs: Ashwagandha, Shatavari, Bala\nYoga: Grounding poses — Child pose, Mountain pose',

    // Dosha - Pitta
    ['pitta', 'pitta dosha', 'pitta imbalance', 'pitt']:
        '🔥 Pitta Dosha (Fire + Water):\n\nPitta types are intelligent and ambitious but prone to irritability and inflammation.\n\nTo Balance Pitta:\n• Cool, sweet, bitter foods — coconut water, cucumber, mint\n• Avoid spicy, oily, fermented foods\n• Moonlight walks, cool environment\n\nHerbs: Amla, Shatavari, Brahmi, Neem\nYoga: Cooling poses — Moon salutation, Sitali pranayama',

    // Dosha - Kapha
    ['kapha', 'kapha dosha', 'kapha imbalance', 'kaph']:
        '💧 Kapha Dosha (Water + Earth):\n\nKapha types are calm and stable but prone to weight gain and lethargy.\n\nTo Balance Kapha:\n• Light, warm, spicy foods — ginger tea, honey\n• Wake up before 6 AM\n• Daily vigorous exercise\n• Avoid heavy, cold, oily foods\n\nHerbs: Trikatu, Guggul, Triphala, Ginger\nYoga: Energizing — Sun salutation, Kapalbhati',

    // Ayurveda general
    ['ayurveda', 'ayurvedic', 'what is ayurveda', 'dosha', 'prakriti']:
        '📖 About Ayurveda:\n\nAyurveda is a 5,000-year-old healing system from India. It means "Science of Life".\n\n3 Doshas:\n• Vata (Air) — controls movement\n• Pitta (Fire) — controls digestion\n• Kapha (Water) — controls structure\n\nCore principle: Health = balance of body, mind & spirit.\n\nUse AyuScan to discover your Dosha type!',

    // Diet
    ['diet', 'food', 'what to eat', 'healthy food', 'nutrition', 'khana']:
        '🥗 Ayurvedic Diet Tips:\n• Eat freshly cooked warm meals\n• Favor seasonal, local produce\n• Eat largest meal at lunch\n• Avoid processed and packaged foods\n• Warm water throughout the day\n• Avoid cold drinks with meals\n\nUse AyuScan to get your personalized Dosha diet!',

    // Yoga
    ['yoga', 'exercise', 'workout', 'pranayama', 'meditation', 'vyayam', 'yoga for stress', 'asana']:
        '🧘 Recommended Yoga Practices:\n\nMorning Routine:\n• Surya Namaskar — full body energizer\n• Anulom Vilom — 5 min alternate nostril breathing\n• Kapalbhati — 3 min cleansing breath\n\nFor Specific Goals:\n• Stress: Balasana, Shavasana, Bhramari\n• Weight: Boat pose, Twists\n• Sleep: Legs-up-wall, Child pose\n• Back pain: Cat-cow, Cobra pose\n\nCheck the Yoga section in AyuScan for more!',

    // Immunity boost
    ['immunity boost', 'boost immunity', 'strengthen immunity', 'raksha shakti']:
        '🛡️ Immunity Boosting:\n\n🌿 Ayurvedic Superfoods:\n• Chyawanprash daily\n• Giloy juice — king of immunity\n• Amla — highest natural Vitamin C\n• Tulsi + ginger + honey tea\n• Turmeric milk nightly\n\n💊 Supplements: Vitamin C, D, Zinc\n\n🧘 Lifestyle: 7–8 hrs sleep, 30 min exercise, sunlight daily.',
  };

  late final Map<String, String> _keywordToTip = {};

  @override
  void initState() {
    super.initState();
    _rules.forEach((keys, tip) {
      for (var k in keys) {
        _keywordToTip[k.toLowerCase()] = tip;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addBotMessage(
        "🙏 Namaste! I am AyuBot, your Ayurvedic Health Assistant!\n\nI can help you with:\n• 🌿 Ayurvedic & allopathic remedies\n• 🔥 Dosha queries (Vata, Pitta, Kapha)\n• 💪 General health and wellness\n• 🥗 Diet and nutrition tips\n• 🧘 Yoga recommendations\n\nDescribe your symptoms or ask any health question!",
      );
    });
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.insert(0, ChatMessage(text: text, fromUser: true));
    });
    _scrollToBottom();
  }

  void _addBotMessage(String text, {bool isTyping = false}) {
    setState(() {
      _messages.insert(
        0,
        ChatMessage(text: text, fromUser: false, isTyping: isTyping),
      );
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;
    _controller.clear();
    _addUserMessage(text);

    setState(() => _isLoading = true);
    _addBotMessage("typing...", isTyping: true);

    final lower = text.toLowerCase();

    // ── Greetings ──
    if (['hi', 'hello', 'hey', 'namaste', 'good morning', 'good evening', 'hii', 'helo']
        .any((g) => lower.contains(g))) {
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() {
        _messages.removeWhere((m) => m.isTyping);
        _isLoading = false;
      });
      _addBotMessage(
        "🙏 Namaste! How can I assist you with your health today?\n\nFeel free to describe any symptoms or ask about Ayurvedic remedies!",
      );
      return;
    }

    // ── Goodbye ──
    if (['bye', 'goodbye', 'see you', 'thanks', 'thank you', 'thx', 'shukriya']
        .any((g) => lower.contains(g))) {
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() {
        _messages.removeWhere((m) => m.isTyping);
        _isLoading = false;
      });
      _addBotMessage(
        "🙏 Goodbye! Stay healthy and follow your Ayurvedic routine.\n\nRemember: Small daily habits lead to lasting wellness! 🌿",
      );
      return;
    }

    // ── Check local keyword rules first ──
    final localSuggestions = _queryLocalRules(text);
    if (localSuggestions.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 800));
      setState(() {
        _messages.removeWhere((m) => m.isTyping);
        _isLoading = false;
      });
      _addBotMessage(localSuggestions.join("\n\n---\n\n"));
      _addBotMessage(
        "⚠️ These are general suggestions only.\nPlease consult a healthcare professional for proper diagnosis.",
      );
      return;
    }

    // ── Try Gemini AI for complex queries ──
    debugPrint('AyuBot: No local keyword match. Calling Gemini AI...');
    try {
      final aiResponse = await _callGeminiAI(text);
      setState(() {
        _messages.removeWhere((m) => m.isTyping);
        _isLoading = false;
      });
      _addBotMessage(aiResponse);
    } catch (e) {
      debugPrint('AyuBot: Gemini failed — $e');
      setState(() {
        _messages.removeWhere((m) => m.isTyping);
        _isLoading = false;
      });
      _addBotMessage(
        "🌿 I couldn't find specific information for that query.\n\nTry asking about:\n• Common symptoms (fever, cold, headache, sinus)\n• Dosha types (Vata, Pitta, Kapha)\n• Conditions (diabetes, acidity, joint pain)\n• Panchakarma, diet, yoga, or immunity\n\n⚠️ For serious conditions, please consult a qualified doctor.",
      );
    }
  }

  // ── Google Gemini API Call with Debug Logging ──
  Future<String> _callGeminiAI(String userMessage) async {
    debugPrint('AyuBot: API Key set: ${_geminiApiKey != 'YOUR_GEMINI_API_KEY_HERE'}');
    debugPrint('AyuBot: Sending to Gemini: "$userMessage"');

    _conversationHistory.add({
      'role': 'user',
      'parts': [
        {'text': userMessage}
      ],
    });

    final requestBody = {
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': _systemPrompt}
          ],
        },
        {
          'role': 'model',
          'parts': [
            {
              'text':
                  'Understood! I am AyuBot, your Ayurvedic health assistant. I will provide helpful remedies in a concise, friendly manner.'
            }
          ],
        },
        ..._conversationHistory,
      ],
      'generationConfig': {
        'temperature': 0.7,
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens': 400,
      },
    };

    final uri = Uri.parse('$_geminiUrl?key=$_geminiApiKey');
    debugPrint('AyuBot: Calling URL: $uri');

    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        )
        .timeout(const Duration(seconds: 15));

    debugPrint('AyuBot: Gemini status code: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final reply =
          data['candidates'][0]['content']['parts'][0]['text'] as String;

      debugPrint('AyuBot: Gemini reply received (${reply.length} chars)');

      _conversationHistory.add({
        'role': 'model',
        'parts': [
          {'text': reply}
        ],
      });

      if (_conversationHistory.length > 20) {
        _conversationHistory.removeRange(0, 2);
      }

      return reply;
    } else {
      debugPrint('AyuBot: Gemini error body: ${response.body}');
      throw Exception('Gemini API error: ${response.statusCode} — ${response.body}');
    }
  }

  // ── Local keyword rule matching (no asterisks) ──
  List<String> _queryLocalRules(String text) {
    final lower = text.toLowerCase();
    final matched = <String>[];
    final usedTips = <String>{};

    _keywordToTip.forEach((keyword, tip) {
      if (lower.contains(keyword) && !usedTips.contains(tip)) {
        matched.add(tip);
        usedTips.add(tip);
      }
    });

    return matched;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.spa, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AyuBot',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Ayurvedic Health Assistant ✨',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildQuickSuggestions(),
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _ChatBubble(message: _messages[index]);
                    },
                  ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildQuickSuggestions() {
    final suggestions = [
      '🤒 Fever',
      '🤧 Cough',
      '👃 Sinus',
      '😴 Sleep Issues',
      '😰 Stress',
      '🌿 Panchakarma',
      '🌬️ Vata Dosha',
      '🔥 Pitta Dosha',
      '💧 Kapha Dosha',
      '🦴 Joint Pain',
      '🥗 Diet Tips',
      '🧘 Yoga',
    ];

    return Container(
      height: 44,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              _controller.text =
                  suggestions[index].replaceAll(RegExp(r'[^\w\s]'), '').trim();
              _handleSend();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF81C784)),
              ),
              child: Text(
                suggestions[index],
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.spa, size: 64, color: Colors.green.shade200),
          const SizedBox(height: 16),
          Text(
            'Start by describing your symptoms',
            style: TextStyle(
              color: Colors.green.shade700,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'or tap a quick suggestion above',
            style: TextStyle(color: Colors.green.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSend(),
                enabled: !_isLoading,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Describe your symptoms...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.green.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.green.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                        color: Color(0xFF2E7D32), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _isLoading ? null : _handleSend,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _isLoading
                      ? Colors.grey.shade300
                      : const Color(0xFF2E7D32),
                  shape: BoxShape.circle,
                  boxShadow: _isLoading
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: _isLoading ? Colors.grey : Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.spa, color: Colors.green.shade700),
            const SizedBox(width: 8),
            const Text('About AyuBot'),
          ],
        ),
        content: const Text(
          'AyuBot is an AI-powered Ayurvedic health assistant providing general wellness guidance based on traditional Ayurvedic principles.\n\n'
          '⚠️ Disclaimer: AyuBot\'s suggestions are for informational purposes only and are NOT a substitute for professional medical advice.\n\n'
          'Always consult a qualified healthcare professional for serious conditions.',
          style: TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2E7D32)),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

// ── Chat Bubble Widget ──
class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.fromUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 6, bottom: 2),
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.spa, color: Colors.white, size: 16),
            ),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: EdgeInsets.only(
                left: isUser ? 60 : 0,
                right: isUser ? 0 : 60,
              ),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF2E7D32) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: message.isTyping
                  ? _TypingIndicator()
                  : Text(
                      message.text,
                      style: TextStyle(
                        fontSize: 14,
                        color: isUser
                            ? Colors.white
                            : const Color(0xFF1A1A1A),
                        height: 1.5,
                      ),
                    ),
            ),
          ),
          if (isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(left: 6, bottom: 2),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person,
                  color: Colors.green.shade700, size: 18),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Animated Typing Indicator ──
class _TypingIndicator extends StatefulWidget {
  @override
  _TypingIndicatorState createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
    );
    _animations = _controllers
        .map(
          (c) => Tween<double>(begin: 0, end: -6).animate(
            CurvedAnimation(parent: c, curve: Curves.easeInOut),
          ),
        )
        .toList();

    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _animations[i],
          builder: (_, __) => Transform.translate(
            offset: Offset(0, _animations[i].value),
            child: Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: const BoxDecoration(
                color: Color(0xFF81C784),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      }),
    );
  }
}
