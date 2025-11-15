# 🌪️ StormShield - AI-Powered Disaster Prediction Platform

<div align="center">

**Predict. Alert. Save Lives.**

[![Flutter](https://img.shields.io/badge/Flutter-3.16+-02569B?logo=flutter)](https://flutter.dev)
[![100% FREE](https://img.shields.io/badge/Cost-$0%20Forever-success)](https://github.com)
[![OpenStreetMap](https://img.shields.io/badge/Maps-OpenStreetMap-7EBC6F)](https://www.openstreetmap.org/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**✅ Ready to Run | ✅ All FREE APIs | ✅ No Credit Card Needed**

</div>

---

## 🎯 About

**StormShield** is an AI-powered disaster management platform that predicts, maps, and responds to natural disasters such as floods, cyclones, earthquakes, heatwaves, and wildfires using **100% FREE APIs**.

### 🎊 **Project Status: COMPLETE & READY TO USE!**

👉 **[START HERE - Quick Setup Guide](./START_HERE.md)** 👈

### Key Features

✅ **Real-time disaster predictions** with AI (Gemini gemini-pro model)  
✅ **Hyper-local alerts** at village/district level  
✅ **Interactive risk maps** showing safe zones with OpenStreetMap  
✅ **Modern Material Design 3 UI** with responsive layouts  
✅ **Multi-channel alerts** via app notifications  
✅ **Cross-platform support** (Web, Android, iOS, Desktop)

---

## 🚀 Quick Start

### Prerequisites

- Flutter SDK ≥ 3.16.0
- Dart SDK ≥ 3.0.0

### Installation

```bash
# 1. Clone repository
git clone https://github.com/yourusername/stormshield.git
cd stormshield

# 2. Install dependencies
flutter pub get

# 3. Configure environment
cp .env.example .env
# Edit .env and add your API keys

# 4. Run app
flutter run
```

---

## 🔑 Required API Keys (All FREE!)

| Service | Purpose | Free Tier | Link | API Key Required |
|---------|---------|-----------|------|------------------|
| **Open-Meteo** | Weather Data | Unlimited | [open-meteo.com](https://open-meteo.com/) | ❌ No key needed |
| **NASA FIRMS** | Wildfires | Unlimited | [firms.modaps.eosdis.nasa.gov](https://firms.modaps.eosdis.nasa.gov/) | ✅ Yes |
| **Gemini AI** | AI Predictions | 60 req/min | [ai.google.dev](https://ai.google.dev/) | ✅ Yes |
| **Supabase** | Database (Optional) | 500MB | [supabase.com](https://supabase.com) | ⚪ Optional |
| **USGS** | Earthquakes | Unlimited | [earthquake.usgs.gov](https://earthquake.usgs.gov/fdsnws/event/1/) | ❌ No key needed |
| **OpenStreetMap** | Maps | Unlimited | [openstreetmap.org](https://www.openstreetmap.org/) | ❌ No key needed |

📖 **Detailed setup guide:** [SETUP.md](./SETUP.md) ⭐ **START HERE!**  
📋 **Full documentation:** [IMPLEMENTATION_GUIDE.md](./IMPLEMENTATION_GUIDE.md)  
🤖 **For AI assistants:** [AI_INSTRUCTIONS.md](./AI_INSTRUCTIONS.md)

---

## 🛠️ Tech Stack

- **Frontend:** Flutter 3.16+ (Web, Android, iOS, Windows, macOS, Linux)
- **Backend:** Supabase (PostgreSQL + PostGIS) - Optional, currently unused
- **APIs:** Open-Meteo (weather), USGS (earthquakes), NASA FIRMS (wildfires), Gemini AI (predictions) - All FREE
- **State Management:** Provider pattern
- **Maps:** OpenStreetMap with flutter_map (FREE, no API key)

---

## 📁 Project Structure

```
lib/
├── config/          # Environment & configuration
├── models/          # Data models
├── services/        # API services
├── providers/       # State management
├── screens/         # UI screens
└── widgets/         # Reusable components
```

---

## 🧪 Testing

```bash
# Run all tests
flutter test

# Build for release
flutter build apk --release   # Android
flutter build ios --release   # iOS
flutter build web --release   # Web
```

---

## 📝 Documentation

- **[Implementation Guide](./IMPLEMENTATION_GUIDE.md)** - Complete step-by-step setup
- **[AI Instructions](./AI_INSTRUCTIONS.md)** - Guide for AI models/assistants
- **[API Documentation](./docs/API.md)** - API endpoints and usage
- **[Database Schema](./database/schema.sql)** - Supabase database structure

---

## 🤝 Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](./CONTRIBUTING.md) for details.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👥 Contact

**Project Lead:** [Your Name](https://github.com/yourusername)  
**Email:** your.email@example.com  
**University:** [Your University Name]

---

<div align="center">

**Made with ❤️ for a safer world**

[⬆ Back to top](#-stormshield---ai-powered-disaster-prediction-platform)

</div>
