# 🚀 StormShield Setup Guide

Complete guide to set up and run StormShield disaster prediction app using **100% FREE APIs**.

---

## 📋 Prerequisites

Before you begin, ensure you have:

- **Flutter SDK** ≥ 3.16.0 ([Install Flutter](https://flutter.dev/docs/get-started/install))
- **Dart SDK** ≥ 3.0.0 (comes with Flutter)
- **Git** (for cloning)
- **Android Studio** or **VS Code** with Flutter extensions
- **Android device/emulator** or **iOS device/simulator**

---

## ⚡ Quick Start (5 minutes)

### Step 1: Install Dependencies

```powershell
# Navigate to project directory
cd StormShield

# Get Flutter packages
flutter pub get
```

### Step 2: Create .env File

```powershell
# Copy the example file
copy .env.example .env
```

### Step 3: Add API Keys (Optional - some work without keys!)

Edit the `.env` file and add your API keys:

```env
# Weather API (NO KEY NEEDED!)
# App uses Open-Meteo by default - 100% free, no registration

# Wildfire Data (KEY REQUIRED)
NASA_FIRMS_API_KEY=your_api_key_here

# AI Predictions (KEY REQUIRED)
GEMINI_API_KEY=your_api_key_here

# Database (OPTIONAL - not actively used yet)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key_here

# Free APIs with NO KEYS NEEDED:
# ✅ Open-Meteo (weather)
# ✅ USGS (earthquakes)
# ✅ OpenStreetMap (maps)
```

### Step 4: Run the App

```powershell
# Run on connected device
flutter run

# Or run on specific device
flutter devices  # List available devices
flutter run -d <device-id>
```

---

## 🔑 Getting FREE API Keys

### 1. Supabase (Database - OPTIONAL)

**Free Tier:** 500MB database, 1GB storage, 50K monthly users

1. Visit: https://supabase.com
2. Click **"Start your project"**
3. Sign up with GitHub or Google (no credit card!)
4. Create new project:
   - Organization: Create new or use existing
   - Project name: `stormshield`
   - Database password: Create a strong password
   - Region: Choose closest to your users
   - Pricing plan: **FREE**
5. Wait 2-3 minutes for setup
6. Get credentials:
   - Go to **Settings** → **API**
   - Copy **Project URL** → paste as `SUPABASE_URL`
   - Copy **anon/public key** → paste as `SUPABASE_ANON_KEY`

**Note:** Supabase is optional. The app works without it. Currently not used for data storage.

---

### 2. Open-Meteo (Weather Data - NO KEY NEEDED!)

**Free Tier:** UNLIMITED requests, 100% FREE forever!

✅ **NO SETUP REQUIRED** - Works instantly!

**Why Open-Meteo?**
- No API key registration needed
- No rate limits
- Instant activation
- Professional-grade weather data
- No subscription fees

**API Endpoint:** https://api.open-meteo.com/v1/forecast

The app uses Open-Meteo as the primary weather source. Just run the app and it works!

---

### 3. NASA FIRMS (Wildfire Data - REQUIRED)

**Free Tier:** UNLIMITED requests!

1. Visit: https://firms.modaps.eosdis.nasa.gov/api/
2. Click **"Request Access"**
3. Fill in the form:
   - Name
   - Email
   - Organization (can be "Personal" or "Student")
   - Purpose: "Disaster monitoring application"
4. Submit and check email
5. You'll receive API key via email (usually within 5 minutes)
6. Copy the MAP_KEY from email
7. Paste as `NASA_FIRMS_API_KEY` in .env

---

### 4. Google Gemini AI (Predictions - REQUIRED)

**Free Tier:** 60 requests/minute, 1,500 requests/day

1. Visit: https://ai.google.dev/
2. Click **"Get API key in Google AI Studio"**
3. Sign in with Google account
4. Click **"Create API Key"**
5. Select or create a Google Cloud project
6. Copy the generated API key
7. Paste as `GEMINI_API_KEY` in .env

**Important:** 
- App uses **gemini-pro** model (stable, production-ready)
- Keep your key secure!
- The key works instantly after creation

---

### 5. USGS Earthquake API (Earthquakes)

✅ **NO API KEY NEEDED** - Public API!

Endpoint: https://earthquake.usgs.gov/fdsnws/event/1/query

Works instantly without any setup!

---

### 6. OpenStreetMap (Maps)

✅ **NO API KEY NEEDED** - Public tiles!

Tile Server: https://tile.openstreetmap.org/

The app automatically displays attribution as required by OSM license.

**Available Layers:**
- Standard Map View
- Humanitarian Map View (optimized for crisis response)

---

## 📱 Running the App

### On Android

```powershell
# Start Android emulator first
# Or connect Android device with USB debugging enabled

flutter run
```

### On iOS (Mac only)

```powershell
# Start iOS simulator first
open -a Simulator

flutter run
```

### On Web

```powershell
flutter run -d chrome
```

### On Windows Desktop

```powershell
flutter run -d windows
```

---

## 🐛 Troubleshooting

### Issue: "Location permission denied"

**Solution:**
- **Android:** Go to Settings → Apps → StormShield → Permissions → Enable Location
- **iOS:** Go to Settings → Privacy → Location Services → StormShield → While Using

### Issue: "API key invalid" error

**Solutions:**
1. Check .env file is in root directory
2. Verify API keys have no extra spaces
3. For OpenWeather: Wait 15 minutes after creating key
4. Restart app: `flutter clean && flutter pub get && flutter run`

### Issue: "No weather data"

**Solutions:**
1. Enable location services on device
2. Check internet connection
3. Verify OpenWeather API key is activated
4. Check API key limits haven't been exceeded

### Issue: "App crashes on startup"

**Solutions:**
```powershell
# Clean build
flutter clean

# Get packages
flutter pub get

# Rebuild
flutter run
```

### Issue: "Couldn't load .env file"

**Solution:**
```powershell
# Make sure .env exists
type .env  # On Windows
cat .env   # On Mac/Linux

# If not found, copy from example
copy .env.example .env  # Windows
cp .env.example .env    # Mac/Linux
```

---

## 🧪 Testing Without API Keys

You can test the app with demo data:

1. Leave .env file empty or use example values
2. App will show fallback data for testing
3. Some features may be limited

---

## 📦 Building for Production

### Android APK

```powershell
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (for Google Play)

```powershell
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS (Mac only)

```powershell
flutter build ios --release
# Then open Xcode to archive and distribute
```

### Windows

```powershell
flutter build windows --release
# Output: build/windows/runner/Release/
```

---

## 🔒 Security Best Practices

1. **Never commit .env file** - Already in .gitignore
2. **Keep API keys private**
3. **Use environment variables** for production
4. **Rotate keys periodically**
5. **Monitor API usage** to avoid hitting limits

---

## 📊 API Rate Limits

| Service | Daily Limit | Per Minute | Notes |
|---------|-------------|------------|-------|
| OpenWeather | 1,000 calls | 60 calls | Track usage carefully |
| Gemini AI | 1,500 calls | 60 calls | Cache predictions |
| NASA FIRMS | Unlimited | Unlimited | 🎉 No limits! |
| USGS | Unlimited | Unlimited | Public data |

---

## 🆘 Need Help?

1. **Check errors:** Look at console output for specific errors
2. **Verify API keys:** Test each API key individually
3. **Check documentation:**
   - [Flutter Docs](https://docs.flutter.dev/)
   - [OpenWeather API](https://openweathermap.org/api)
   - [Gemini AI](https://ai.google.dev/)
4. **Location issues:** Ensure GPS is enabled on device

---

## ✅ Checklist

Before running the app, make sure:

- [ ] Flutter SDK installed and in PATH
- [ ] Project dependencies installed (`flutter pub get`)
- [ ] .env file created with API keys
- [ ] OpenWeather API key activated (wait 15 min)
- [ ] Location permission enabled on device
- [ ] Internet connection active
- [ ] Device/emulator running

---

## 🎉 You're Ready!

Your StormShield app is now configured with 100% FREE APIs and ready to predict disasters!

```powershell
flutter run
```

Stay safe! 🌪️
