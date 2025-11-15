import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';
import '../models/chat_message.dart';

/// Disaster assistance chatbot service using Hugging Face API
class ChatbotService {
  final String _apiKey = EnvConfig.huggingFaceApiKey;
  
  // Using Hugging Face's router inference endpoint with a lightweight conversational model
  // DialoGPT-small is faster and efficient while maintaining good quality responses
  static const String _apiUrl = 'https://router.huggingface.co/hf-inference/models/microsoft/DialoGPT-small';

  /// Send a message and get chatbot response
  Future<ChatMessage> sendMessage(String userMessage, List<ChatMessage> chatHistory) async {
    try {
      // Build conversation context
      final conversation = _buildConversationContext(userMessage, chatHistory);
      
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'inputs': {
            'text': conversation,
            'past_user_inputs': _getPastUserInputs(chatHistory),
            'generated_responses': _getPastBotResponses(chatHistory),
          },
          'parameters': {
            'max_length': 150,
            'temperature': 0.7,
            'top_p': 0.9,
            'do_sample': true,
          },
          'options': {
            'wait_for_model': true,
            'use_cache': false,
          }
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String botResponse;
        
        // Handle different response formats
        if (data is Map && data.containsKey('generated_text')) {
          botResponse = data['generated_text'];
        } else if (data is List && data.isNotEmpty) {
          botResponse = data[0]['generated_text'] ?? 'I apologize, but I encountered an error. Please try rephrasing your question.';
        } else {
          botResponse = 'I apologize, but I encountered an error. Please try rephrasing your question.';
        }
        
        // Clean up the response
        botResponse = _cleanResponse(botResponse, userMessage);
        
        return ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: botResponse,
          isUser: false,
          timestamp: DateTime.now(),
        );
      } else if (response.statusCode == 503) {
        // Model is loading
        return ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: 'The AI model is loading. Please wait a moment and try again.',
          isUser: false,
          timestamp: DateTime.now(),
        );
      } else {
        throw Exception('Failed to get response: ${response.statusCode}');
      }
    } catch (e) {
      print('Chatbot error: $e');
      // Return helpful fallback response based on keywords
      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: _getFallbackResponse(userMessage),
        isUser: false,
        timestamp: DateTime.now(),
      );
    }
  }

  /// Build conversation context with disaster focus
  String _buildConversationContext(String userMessage, List<ChatMessage> chatHistory) {
    final buffer = StringBuffer();
    
    // Add expert disaster assistant context
    if (chatHistory.isEmpty) {
      buffer.writeln('You are an expert disaster response assistant specializing in emergency safety, first aid, and disaster preparedness.');
      buffer.writeln('Provide clear, concise, life-saving advice for emergencies.');
      buffer.writeln('');
    }
    
    // Add recent conversation history (last 3 exchanges)
    final recentHistory = chatHistory.length > 6 ? chatHistory.sublist(chatHistory.length - 6) : chatHistory;
    for (var message in recentHistory) {
      if (message.isUser) {
        buffer.writeln('User: ${message.text}');
      } else {
        buffer.writeln('Assistant: ${message.text}');
      }
    }
    
    buffer.write('User: $userMessage\nAssistant (Expert Disaster Advisor):');
    return buffer.toString();
  }

  /// Get past user inputs for conversation
  List<String> _getPastUserInputs(List<ChatMessage> chatHistory) {
    return chatHistory
        .where((msg) => msg.isUser)
        .map((msg) => msg.text)
        .toList();
  }

  /// Get past bot responses for conversation
  List<String> _getPastBotResponses(List<ChatMessage> chatHistory) {
    return chatHistory
        .where((msg) => !msg.isUser)
        .map((msg) => msg.text)
        .toList();
  }

  /// Clean up bot response
  String _cleanResponse(String response, String userMessage) {
    // Remove the user message if it's included in response
    response = response.replaceAll(userMessage, '').trim();
    
    // Remove common prefixes
    response = response.replaceAll(RegExp(r'^(Assistant:|Bot:|AI:)\s*', caseSensitive: false), '');
    
    // Ensure it's disaster-focused if it seems off-topic
    if (!_isDisasterRelated(response)) {
      return _getContextualResponse(userMessage);
    }
    
    return response.trim();
  }

  /// Check if response is disaster-related
  bool _isDisasterRelated(String text) {
    final keywords = ['emergency', 'disaster', 'safety', 'evacuation', 'first aid', 
                     'flood', 'earthquake', 'fire', 'cyclone', 'storm', 'rescue',
                     'help', 'danger', 'warning', 'prepare', 'kit', 'shelter'];
    
    final lowerText = text.toLowerCase();
    return keywords.any((keyword) => lowerText.contains(keyword));
  }

  /// Get contextual response based on user message
  String _getContextualResponse(String userMessage) {
    final lower = userMessage.toLowerCase();
    
    if (lower.contains('flood')) {
      return 'During floods: Move to higher ground immediately. Avoid walking through moving water (6 inches can knock you down). Turn off utilities if instructed. Never drive through flooded roads.';
    } else if (lower.contains('earthquake')) {
      return 'During earthquake: DROP, COVER, and HOLD ON. Stay indoors if inside, move away from buildings if outside. After shaking stops, check for injuries and evacuate if building is damaged.';
    } else if (lower.contains('fire') || lower.contains('wildfire')) {
      return 'During wildfire: Evacuate immediately if ordered. Close all windows and doors. Wear N95 mask to protect from smoke. If trapped, call 911 and signal for help from window.';
    } else if (lower.contains('cyclone') || lower.contains('hurricane') || lower.contains('storm')) {
      return 'During cyclone: Stay indoors away from windows. Go to lowest floor or interior room. If evacuation ordered, leave immediately. Never go outside during eye of storm.';
    } else if (lower.contains('first aid') || lower.contains('injury')) {
      return 'Basic first aid: Call emergency services first. For bleeding: apply direct pressure with clean cloth. For burns: cool with water for 10+ minutes. For choking: perform Heimlich maneuver.';
    } else if (lower.contains('kit') || lower.contains('prepare')) {
      return 'Emergency kit essentials: Water (1 gallon/person/day for 3 days), non-perishable food, flashlight, battery radio, first aid kit, medications, whistle, dust mask, phone charger.';
    } else {
      return 'I can help with emergency guidance during disasters. Ask me about: floods, earthquakes, wildfires, cyclones, first aid, evacuation procedures, or emergency kit preparation.';
    }
  }

  /// Get fallback response when API fails
  String _getFallbackResponse(String userMessage) {
    final lower = userMessage.toLowerCase();
    
    // Check for specific disaster types with expert detailed responses
    if (lower.contains('flood')) {
      return '🌊 **FLOOD EXPERT ADVICE**:\n\n'
          '⚠️ IMMEDIATE: Move to higher ground NOW. Just 6 inches of moving water can knock you down, 12 inches can carry away a car.\n\n'
          '✓ Turn off gas, electricity, and water if safe\n'
          '✓ Never walk/drive through flood water\n'
          '✓ If trapped, go to highest floor (not attic without roof access)\n'
          '✓ Avoid touching electrical equipment when wet\n'
          '✓ After flood: Don\'t return until authorities say safe, check for structural damage, discard contaminated food/water';
    } else if (lower.contains('earthquake')) {
      return '🏚️ **EARTHQUAKE EXPERT ADVICE**:\n\n'
          '⚠️ DURING SHAKING: DROP-COVER-HOLD ON\n'
          '• Indoors: Get under sturdy desk/table, protect head, stay until shaking stops\n'
          '• Outdoors: Move away from buildings, trees, powerlines to open area\n'
          '• In car: Stop safely, stay inside until shaking stops\n\n'
          '✓ AFTER: Check injuries, expect aftershocks (can be strong)\n'
          '✓ Turn off gas if you smell it\n'
          '✓ Inspect home for cracks/damage before entering\n'
          '✓ Stay away from damaged buildings';
    } else if (lower.contains('fire') || lower.contains('wildfire')) {
      return '🔥 **WILDFIRE EXPERT ADVICE**:\n\n'
          '⚠️ EVACUATION CRITICAL: When authorities order evacuation, GO IMMEDIATELY. Wildfires can travel 14 mph.\n\n'
          '✓ Close ALL windows/doors (not locked)\n'
          '✓ Turn off gas, leave lights on for visibility\n'
          '✓ Wear N95 mask + long sleeves/pants\n'
          '✓ Take multiple routes, avoid canyons\n'
          '✓ If trapped: Stay in cleared area, car with windows up, or building. Call 911, signal location\n\n'
          'SMOKE INHALATION: Get low, breathe through cloth, exit immediately';
    } else if (lower.contains('cyclone') || lower.contains('hurricane') || lower.contains('typhoon')) {
      return '🌀 **CYCLONE EXPERT ADVICE**:\n\n'
          '⚠️ PRE-STORM: Evacuate if ordered (coastal/mobile homes). Storm surge is #1 killer.\n\n'
          '✓ Go to interior room on LOWEST floor (not basement if flooding risk)\n'
          '✓ Stay away from windows, doors, skylights\n'
          '✓ Bring emergency kit, battery radio\n'
          '✓ NEVER go outside during "eye" calm period - winds return violently\n\n'
          '✓ AFTER: Watch for flooding, downed powerlines, damaged buildings. Stay inside until all-clear given';
    } else if (lower.contains('drought')) {
      return '☀️ **DROUGHT EXPERT ADVICE**:\n\n'
          '⚠️ WATER CONSERVATION CRITICAL:\n'
          '• Store 1 gallon/person/day (minimum 3-day supply)\n'
          '• Fix leaks immediately\n'
          '• Reuse greywater for plants\n\n'
          '✓ HEALTH: Stay hydrated, monitor elderly/children\n'
          '✓ WILDFIRE RISK: Extreme during droughts - clear vegetation, create defensible space\n'
          '✓ Follow local water restrictions\n'
          '✓ Have water purification tablets ready';
    } else if (lower.contains('heatwave') || lower.contains('heat')) {
      return '🌡️ **HEATWAVE EXPERT ADVICE**:\n\n'
          '⚠️ HEAT KILLS: More deaths than all other weather disasters combined.\n\n'
          '✓ HYDRATION: Drink water every 15-20 min (not alcohol/caffeine)\n'
          '✓ Stay indoors 10am-4pm (peak heat)\n'
          '✓ NEVER leave children/pets in cars (deadly in minutes)\n\n'
          '🚨 HEAT EXHAUSTION: Heavy sweating, weakness, nausea → Move to cool place, drink water\n'
          '🚨 HEAT STROKE: Hot dry skin, confusion, unconsciousness → CALL 911, cool body with water immediately';
    } else if (lower.contains('first aid') || lower.contains('injury') || lower.contains('bleeding')) {
      return '🏥 **FIRST AID EXPERT ADVICE**:\n\n'
          '⚠️ ALWAYS CALL 911 FIRST for serious injuries\n\n'
          '🩸 SEVERE BLEEDING:\n'
          '1. Apply direct pressure with clean cloth (5-10 min)\n'
          '2. Don\'t remove cloth if soaked - add more\n'
          '3. Elevate injured area above heart\n'
          '4. Use tourniquet ONLY if life-threatening limb bleeding\n\n'
          '🔥 BURNS: Cool with water 10-20 min, cover with clean cloth, NO ice/butter\n'
          '💨 CHOKING: 5 back blows, then 5 abdominal thrusts (Heimlich), repeat';
    } else if (lower.contains('cpr')) {
      return '❤️ **CPR EXPERT ADVICE**:\n\n'
          '⚠️ CRITICAL STEPS:\n'
          '1. CHECK: Tap shoulder, shout "Are you OK?"\n'
          '2. CALL 911 immediately (or have someone else call)\n'
          '3. CHEST COMPRESSIONS:\n'
          '   • Place heel of hand on center of chest\n'
          '   • Other hand on top, interlock fingers\n'
          '   • Push HARD and FAST: 2 inches deep, 100-120/min\n'
          '   • Give 30 compressions\n'
          '4. RESCUE BREATHS: Tilt head, 2 breaths (1 sec each)\n'
          '5. REPEAT: 30 compressions, 2 breaths until help arrives\n\n'
          '✓ Use AED if available - follow voice prompts\n'
          '✓ Don\'t stop compressions for >10 seconds';
    } else if (lower.contains('evacuation') || lower.contains('evacuate')) {
      return '🚨 **EVACUATION EXPERT ADVICE**:\n\n'
          '⚠️ When ordered to evacuate, DO NOT DELAY. Leave immediately.\n\n'
          '✓ TAKE:\n'
          '• Emergency kit (water, food, first aid)\n'
          '• Medications (7-day supply)\n'
          '• Important documents (insurance, ID, bank)\n'
          '• Phone charger, cash\n'
          '• Pet carriers + supplies\n\n'
          '✓ BEFORE LEAVING:\n'
          '• Lock doors/windows\n'
          '• Turn off utilities if instructed\n'
          '• Leave note with departure time/destination\n'
          '• Follow designated evacuation routes\n'
          '• Tell family/friends where you\'re going\n\n'
          '⚠️ Do NOT return until officials say safe';
    } else if (lower.contains('emergency kit') || lower.contains('prepare')) {
      return '🎒 **EMERGENCY KIT EXPERT CHECKLIST**:\n\n'
          '💧 WATER: 1 gallon/person/day (3-7 day supply)\n'
          '🥫 FOOD: Non-perishable (3-7 days)\n'
          '📻 COMMUNICATION:\n'
          '• Battery/hand-crank radio (NOAA weather)\n'
          '• Flashlight + extra batteries\n'
          '• Cell phone + portable charger\n'
          '• Whistle (signal for help)\n\n'
          '🏥 MEDICAL:\n'
          '• First aid kit\n'
          '• Prescription medications (7-day supply)\n'
          '• Medical items (glasses, hearing aids)\n\n'
          '📄 DOCUMENTS: Copies of insurance, ID, bank records (waterproof container)\n'
          '💵 CASH: ATMs may not work\n'
          '😷 SANITATION: Masks, hand sanitizer, soap\n'
          '🔧 TOOLS: Wrench, pliers (turn off utilities)';
    } else if (lower.contains('shelter')) {
      return '🏠 **SHELTER EXPERT ADVICE**:\n\n'
          '⚠️ EMERGENCY SHELTERS:\n'
          '✓ Know locations BEFORE disaster (Red Cross, schools, community centers)\n'
          '✓ Bring: ID, medications, blanket, comfort items\n'
          '✓ Register with staff for family reunification\n\n'
          '📋 SHELTER RULES:\n'
          '• No weapons, alcohol, drugs\n'
          '• Respect others\' space and belongings\n'
          '• Follow staff instructions\n'
          '• Keep area clean\n\n'
          '🐾 PETS: Most shelters can\'t accept pets - find pet-friendly shelter or kennel in advance\n\n'
          '⚠️ Special needs: Call ahead if you need medical equipment, dietary restrictions';
    } else if (lower.contains('water') || lower.contains('clean') || lower.contains('purif')) {
      return '💧 **WATER SAFETY EXPERT ADVICE**:\n\n'
          '⚠️ STORAGE:\n'
          '• 1 gallon/person/day minimum\n'
          '• Store in cool, dark place\n'
          '• Replace every 6 months\n'
          '• Food-grade containers only\n\n'
          '🚨 PURIFICATION (when tap water unsafe):\n'
          '1. BOILING: Rolling boil for 1 minute (3 min at high altitude) - MOST EFFECTIVE\n'
          '2. CHLORINE: 8 drops bleach/gallon, wait 30 min\n'
          '3. TABLETS: Follow package directions\n'
          '4. FILTER: Use certified water filter\n\n'
          '⚠️ NEVER drink flood water, standing water, or water with strange color/smell\n'
          '✓ After disaster: Wait for official "all clear" before using tap water';
    } else if (lower.contains('shock') || lower.contains('trauma')) {
      return '🚑 **SHOCK/TRAUMA EXPERT ADVICE**:\n\n'
          '⚠️ SIGNS OF SHOCK:\n'
          '• Pale, cold, clammy skin\n'
          '• Rapid pulse\n'
          '• Rapid breathing\n'
          '• Weakness, confusion\n\n'
          '🚨 IMMEDIATE ACTIONS:\n'
          '1. CALL 911\n'
          '2. Lay person down, elevate legs 12 inches (unless head/spine injury)\n'
          '3. Keep warm with blanket\n'
          '4. Do NOT give food or water\n'
          '5. Monitor breathing and pulse\n'
          '6. If unconscious and breathing: recovery position (on side)\n\n'
          '⚠️ Shock is LIFE-THREATENING - get emergency help immediately';
    } else if (lower.contains('broken') || lower.contains('fracture') || lower.contains('bone')) {
      return '🦴 **FRACTURE EXPERT ADVICE**:\n\n'
          '⚠️ SIGNS: Severe pain, swelling, deformity, inability to move, bone visible\n\n'
          '🚨 DO:\n'
          '1. CALL 911 for severe breaks\n'
          '2. IMMOBILIZE: Don\'t try to straighten bone\n'
          '3. Apply ice (wrapped in cloth) to reduce swelling\n'
          '4. Splint if trained: Immobilize joints above and below break\n'
          '5. Elevate injured area\n'
          '6. Treat for shock\n\n'
          '❌ DON\'T:\n'
          '• Don\'t move person unless necessary\n'
          '• Don\'t try to realign bone\n'
          '• Don\'t give food/drink if surgery possible';
    } else {
      return '⚠️ **DISASTER EXPERT ASSISTANT READY**\n\n'
          'I\'m specialized in emergency response and disaster preparedness. Ask me about:\n\n'
          '🌊 Floods - evacuation, safety measures\n'
          '🏚️ Earthquakes - DROP-COVER-HOLD, aftershocks\n'
          '🔥 Wildfires - evacuation zones, smoke safety\n'
          '🌀 Cyclones - shelter-in-place, storm surge\n'
          '🏥 First Aid - bleeding, burns, CPR, choking\n'
          '🎒 Emergency Kits - supplies, preparation\n'
          '🚨 Evacuation - routes, timing, what to take\n'
          '💧 Water Safety - purification, storage\n'
          '🦴 Injuries - fractures, shock, trauma\n\n'
          'Ask specific questions for detailed expert guidance!';
    }
  }

  /// Get suggested questions for users
  List<String> getSuggestedQuestions() {
    return [
      'What should I do during an earthquake?',
      'How to perform first aid for burns?',
      'What items should be in my emergency kit?',
      'How to stay safe during a flood?',
      'What to do if caught in a wildfire?',
      'How to prepare for a cyclone?',
      'CPR steps for adults',
      'When should I evacuate?',
    ];
  }
}
