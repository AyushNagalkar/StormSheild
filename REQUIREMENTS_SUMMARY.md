# 📋 STORMSHIELD - REQUIREMENTS & INSTRUCTIONS SUMMARY

## For: Other AI Models, Developers, or Collaborators

---

## 🎯 PROJECT OVERVIEW

**Name:** StormShield  
**Type:** AI-Powered Disaster Prediction & Management Platform  
**Budget:** $0 (100% FREE APIs and services)  
**Timeline:** 4-6 hours for MVP, 2-3 weeks for full features  
**Difficulty:** Intermediate (requires Flutter knowledge)

---

## 📦 WHAT HAS BEEN CREATED

### 1. Documentation Files ✅

| File | Purpose | Location |
|------|---------|----------|
| **IMPLEMENTATION_GUIDE.md** | Complete step-by-step guide (10,000+ words) | `/IMPLEMENTATION_GUIDE.md` |
| **AI_INSTRUCTIONS.md** | Quick reference for AI models | `/AI_INSTRUCTIONS.md` |
| **README.md** | Project overview and quick start | `/README.md` |
| **.env.example** | API keys template | `/.env.example` |
| **.env** | Actual API keys (DO NOT COMMIT) | `/.env` |

### 2. Project Structure ✅

```
stormshield/
├── lib/              # Flutter source code (needs implementation)
├── assets/           # Images, icons (empty, needs assets)
├── database/         # SQL schemas (needs creation)
├── test/             # Test files (needs implementation)
├── .env             # Environment variables (needs API keys)
├── .env.example     # Example env file ✅
├── pubspec.yaml     # Dependencies (needs updating)
├── README.md        # Project readme ✅
├── IMPLEMENTATION_GUIDE.md  # Complete guide ✅
└── AI_INSTRUCTIONS.md       # AI reference ✅
```

---

## 🔧 WHAT NEEDS TO BE DONE

### Phase 1: Setup (30 minutes)

```bash
# 1. Get API Keys
- Register at supabase.com → Get SUPABASE_URL and SUPABASE_ANON_KEY
- Register at openweathermap.org/api → Get OPENWEATHER_API_KEY
- Register at firms.modaps.eosdis.nasa.gov → Get NASA_FIRMS_API_KEY
- Register at ai.google.dev → Get GEMINI_API_KEY

# 2. Update .env file
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_key_here
OPENWEATHER_API_KEY=your_key_here
NASA_FIRMS_API_KEY=your_key_here
GEMINI_API_KEY=your_key_here

# 3. Update pubspec.yaml dependencies
flutter pub add supabase_flutter http provider flutter_dotenv geolocator
```

### Phase 2: Database Setup (20 minutes)

```sql
-- Go to Supabase Dashboard → SQL Editor
-- Copy SQL from IMPLEMENTATION_GUIDE.md Section 4.1
-- Run the schema creation script
-- Verify tables are created
```

### Phase 3: Implement Core Files (2 hours)

Priority order:

1. **lib/config/env_config.dart** (5 min)
2. **lib/config/supabase_config.dart** (5 min)
3. **lib/models/alert.dart** (10 min)
4. **lib/services/weather_service.dart** (20 min)
5. **lib/services/earthquake_service.dart** (15 min)
6. **lib/services/wildfire_service.dart** (15 min)
7. **lib/services/ai_prediction_service.dart** (20 min)
8. **lib/main.dart** (15 min)
9. **lib/screens/home_screen.dart** (30 min)

### Phase 4: UI Implementation (2 hours)

1. Dashboard screen with risk scores
2. Map view with markers
3. Alerts list screen
4. Alert detail screen
5. Citizen reports screen

### Phase 5: Testing & Deployment (1 hour)

1. Unit tests for services
2. Integration tests for API calls
3. Build APK for Android
4. Deploy web version

---

## 🎓 STEP-BY-STEP INSTRUCTIONS FOR AI MODELS

### Instruction Set 1: Create Config Files

```
TASK: Create lib/config/env_config.dart

REQUIREMENTS:
1. Import flutter_dotenv package
2. Create static class EnvConfig
3. Add static getters for all environment variables:
   - supabaseUrl
   - supabaseAnonKey
   - openWeatherKey
   - nasaFirmsKey
   - geminiApiKey
4. Add validation method isConfigured()
5. Handle null/empty values gracefully

CODE STYLE: Use static methods, follow Dart conventions
```

### Instruction Set 2: Create Weather Service

```
TASK: Create lib/services/weather_service.dart

REQUIREMENTS:
1. Import http package
2. Create class WeatherService
3. Implement methods:
   - getCurrentWeather(lat, lon) → Map<String, dynamic>
   - getForecast(lat, lon) → List<dynamic>
   - analyzeFloodRisk(lat, lon) → double (0-1 range)
   - analyzeCycloneRisk(lat, lon) → double
   - analyzeHeatwaveRisk(lat, lon) → double
4. Use OpenWeather API endpoint: api.openweathermap.org/data/2.5/weather
5. Handle errors with try-catch
6. Return parsed JSON data

RATE LIMIT: 1000 calls/day, cache for 6 hours
```

### Instruction Set 3: Create Alert Model

```
TASK: Create lib/models/alert.dart

REQUIREMENTS:
1. Create class Alert with properties:
   - id (String)
   - title (String)
   - message (String)
   - severity (String: low/medium/high/critical)
   - issuedAt (DateTime)
   - expiresAt (DateTime?)
   - locationName (String?)
   - safetyInstructions (List<String>)
2. Add factory constructor fromJson(Map<String, dynamic>)
3. Add helper methods:
   - severityColor → Color (green/orange/red based on severity)
   - severityIcon → IconData
   - isActive → bool (check if not expired)
4. Use immutable pattern (final fields)

CODE STYLE: Follow Flutter best practices
```

### Instruction Set 4: Create Main App

```
TASK: Create lib/main.dart

REQUIREMENTS:
1. Initialize flutter_dotenv in main()
2. Initialize Supabase before runApp()
3. Wrap app with MultiProvider:
   - AuthProvider
   - AlertProvider
   - LocationProvider
4. Create MaterialApp with:
   - Theme (Material 3)
   - Dark theme support
   - Initial route: SplashScreen
5. Handle initialization errors
6. Show loading indicator during setup

ERROR HANDLING: Graceful error messages if API keys missing
```

### Instruction Set 5: Create Home Screen

```
TASK: Create lib/screens/home_screen.dart

REQUIREMENTS:
1. Stateful widget with bottom navigation
2. Navigation items:
   - Dashboard (risk overview)
   - Map (interactive map)
   - Alerts (active alerts list)
   - Reports (citizen reports)
3. Show AppBar with:
   - Title: "StormShield"
   - Actions: Notification icon with badge
4. Implement navigation between screens
5. Add floating action button for "Report Disaster"
6. Use Material 3 NavigationBar widget

UI: Follow Material Design guidelines, responsive layout
```

---

## 🔍 KEY ALGORITHMS

### 1. Flood Risk Calculation

```dart
Future<double> analyzeFloodRisk(lat, lon) {
  // 1. Get 5-day forecast
  forecast = await getForecast(lat, lon);
  
  // 2. Sum rainfall in next 24 hours
  totalRainfall = sum(forecast[0..8]['rain']['3h']);
  
  // 3. Calculate risk
  if (totalRainfall > 50mm) return 0.9;  // Critical
  if (totalRainfall > 20mm) return 0.6;  // High
  if (totalRainfall > 10mm) return 0.3;  // Medium
  return 0.1;                             // Low
}
```

### 2. Earthquake Risk Calculation

```dart
Future<double> predictEarthquakeRisk(lat, lon) {
  // 1. Get earthquakes in last 30 days
  earthquakes = await getRecentEarthquakes(bbox, days=30);
  
  // 2. Calculate metrics
  avgMagnitude = sum(magnitudes) / count;
  frequency = count / 30;  // per day
  
  // 3. Calculate risk (weighted)
  risk = (avgMagnitude / 10) * 0.5 + (frequency / 5) * 0.5;
  
  return risk.clamp(0.0, 1.0);
}
```

### 3. AI Prediction with Gemini

```dart
Future<Map<String, dynamic>> analyzeWithAI(data) {
  // 1. Create structured prompt
  prompt = """
  Analyze disaster data:
  - Current weather: ${data.weather}
  - Risk scores: ${data.risks}
  - Historical patterns: ${data.history}
  
  Return JSON with:
  - highestRisks: ["disaster1", "disaster2"]
  - timeframes: {"disaster1": "24h"}
  - actions: ["action1", "action2"]
  - threatLevel: "low|medium|high|critical"
  """;
  
  // 2. Call Gemini API
  response = await http.post(
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent',
    headers: {'x-goog-api-key': geminiKey},
    body: {'contents': [{'parts': [{'text': prompt}]}]}
  );
  
  // 3. Extract and parse JSON from response
  return parseJSON(response.text);
}
```

---

## 🎨 UI DESIGN GUIDELINES

### Color Palette

```dart
// Severity Colors
final Map<String, Color> severityColors = {
  'low': Color(0xFF10B981),      // Green
  'medium': Color(0xFFF97316),   // Orange
  'high': Color(0xFFEF4444),     // Red
  'critical': Color(0xFFDC2626), // Dark Red
};

// Disaster Colors
final Map<String, Color> disasterColors = {
  'flood': Color(0xFF3B82F6),    // Blue
  'cyclone': Color(0xFFEF4444),  // Red
  'earthquake': Color(0xFFF59E0B), // Amber
  'wildfire': Color(0xFFDC2626), // Dark Red
  'heatwave': Color(0xFFF97316), // Orange
  'drought': Color(0xFFA16207),  // Brown
};
```

### Component Hierarchy

```
HomeScreen
├── AppBar (title, notifications)
├── NavigationBar (bottom)
│   ├── Dashboard Tab
│   │   ├── RiskScoreCard (per disaster)
│   │   ├── WeatherWidget
│   │   └── RecentAlertsCarousel
│   ├── Map Tab
│   │   ├── GoogleMap
│   │   ├── HeatmapLayer
│   │   ├── AlertMarkers
│   │   └── ResourceMarkers
│   ├── Alerts Tab
│   │   ├── FilterChips (by severity)
│   │   └── AlertsList
│   │       └── AlertCard (per alert)
│   └── Reports Tab
│       ├── CreateReportFAB
│       └── ReportsList
│           └── ReportCard
└── FloatingActionButton (Report Disaster)
```

---

## 🧪 TESTING STRATEGY

### Unit Tests (test/services/)

```dart
// weather_service_test.dart
test('Get current weather returns valid data', () async {
  final service = WeatherService();
  final weather = await service.getCurrentWeather(19.0760, 72.8777);
  expect(weather, isNotNull);
  expect(weather['main'], isNotNull);
  expect(weather['main']['temp'], isA<num>());
});

test('Flood risk calculation within range', () async {
  final service = WeatherService();
  final risk = await service.analyzeFloodRisk(19.0760, 72.8777);
  expect(risk, greaterThanOrEqualTo(0.0));
  expect(risk, lessThanOrEqualTo(1.0));
});
```

### Integration Tests (integration_test/)

```dart
// app_test.dart
testWidgets('Complete user flow', (tester) async {
  // 1. App launches
  await tester.pumpWidget(StormShieldApp());
  await tester.pumpAndSettle();
  
  // 2. Dashboard loads
  expect(find.text('Dashboard'), findsOneWidget);
  
  // 3. Navigate to Map
  await tester.tap(find.text('Map'));
  await tester.pumpAndSettle();
  
  // 4. Map displays
  expect(find.byType(GoogleMap), findsOneWidget);
});
```

---

## 📊 SUCCESS METRICS

| Metric | Target | How to Measure |
|--------|--------|----------------|
| **Prediction Accuracy** | > 80% | Compare predictions vs actual events |
| **Response Time** | < 3 sec | API call to prediction |
| **Alert Delivery** | < 30 sec | Prediction to notification |
| **User Engagement** | > 60% | Weekly active users |
| **Crash Rate** | < 1% | Firebase Crashlytics |
| **App Size** | < 50 MB | APK/IPA size |
| **Battery Usage** | < 5%/hour | Android battery stats |

---

## 🚀 DEPLOYMENT CHECKLIST

### Pre-Deployment

- [ ] All API keys configured in .env
- [ ] Database tables created in Supabase
- [ ] All services implemented and tested
- [ ] UI screens completed
- [ ] App tested on physical devices
- [ ] Error handling implemented
- [ ] Loading states added
- [ ] Offline mode working
- [ ] App icon and splash screen added
- [ ] App name and package updated

### Android Release

```bash
# 1. Update version in pubspec.yaml
version: 1.0.0+1

# 2. Generate signing key
keytool -genkey -v -keystore stormshield-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias stormshield

# 3. Create android/key.properties
storePassword=your_password
keyPassword=your_password
keyAlias=stormshield
storeFile=../stormshield-key.jks

# 4. Build release
flutter build apk --release
flutter build appbundle --release

# 5. Test release build
flutter install --release
```

### iOS Release

```bash
# 1. Update version
# 2. Configure signing in Xcode
# 3. Build archive
flutter build ios --release

# 4. Open Xcode
open ios/Runner.xcworkspace

# 5. Product → Archive → Upload to App Store
```

### Web Release

```bash
# 1. Build for web
flutter build web --release

# 2. Deploy to Vercel
npm i -g vercel
cd build/web
vercel --prod

# Or deploy to Netlify
netlify deploy --prod --dir=build/web
```

---

## 📝 NOTES FOR AI ASSISTANTS

### When implementing this project:

1. **Start with configuration files** - They're the foundation
2. **Implement services before UI** - Test APIs independently
3. **Use sample data first** - Don't wait for real API data
4. **Build incrementally** - One feature at a time
5. **Test early and often** - Catch errors before they compound
6. **Handle errors gracefully** - Show user-friendly messages
7. **Cache aggressively** - Respect free tier limits
8. **Document as you go** - Add comments for complex logic

### Common Pitfalls:

❌ **Don't** hardcode API keys in source code  
✅ **Do** use .env file and gitignore it

❌ **Don't** make synchronous API calls  
✅ **Do** use async/await and show loading states

❌ **Don't** ignore rate limits  
✅ **Do** implement caching and batch requests

❌ **Don't** assume internet is always available  
✅ **Do** implement offline mode with cached data

❌ **Don't** skip error handling  
✅ **Do** catch and display errors gracefully

---

## 🎯 QUICK COMMANDS REFERENCE

```bash
# Setup
flutter create stormshield
cd stormshield
flutter pub get

# Development
flutter run                    # Run on connected device
flutter run -d chrome         # Run on web
flutter run --release         # Release mode

# Testing
flutter test                  # Unit tests
flutter test integration_test/ # Integration tests
flutter analyze               # Static analysis

# Building
flutter build apk --release   # Android APK
flutter build appbundle       # Android AAB
flutter build ios --release   # iOS
flutter build web --release   # Web

# Maintenance
flutter clean                 # Clean build files
flutter pub upgrade           # Update dependencies
flutter doctor               # Check setup
```

---

## 📞 SUPPORT & RESOURCES

### Official Documentation
- Flutter: https://docs.flutter.dev/
- Supabase: https://supabase.com/docs
- OpenWeather: https://openweathermap.org/api/one-call-3
- Gemini AI: https://ai.google.dev/docs

### Community
- Flutter Discord: https://discord.gg/flutter
- Stack Overflow: [flutter] tag
- GitHub Discussions: Enable in repo settings

### Contact
- Email: your.email@example.com
- GitHub: @yourusername
- LinkedIn: your-profile

---

**End of Requirements & Instructions Summary**

*Last Updated: November 6, 2025*
*Version: 1.0.0*
