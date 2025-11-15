# ⚡ StormShield - Quick Start

Get StormShield running in **5 minutes** with FREE APIs!

---

## ✅ Step 1: Install Dependencies

```powershell
flutter pub get
```

---

## ✅ Step 2: Get FREE API Keys

### Required Keys (3 APIs - all free, no credit card):

#### 1. **OpenWeather API** (2 minutes)
   - Visit: https://openweathermap.org/api
   - Sign up (free account)
   - Get API key from dashboard
   - ⏰ Wait 10-15 minutes for activation

#### 2. **NASA FIRMS** (2 minutes)
   - Visit: https://firms.modaps.eosdis.nasa.gov/api/
   - Request access
   - Check email for MAP_KEY

#### 3. **Google Gemini AI** (1 minute)
   - Visit: https://ai.google.dev/
   - Sign in with Google
   - Get API key

---

## ✅ Step 3: Configure .env File

Create `.env` file in project root:

```env
# Copy .env.example to .env first
OPENWEATHER_API_KEY=your_key_here
NASA_FIRMS_API_KEY=your_key_here
GEMINI_API_KEY=your_key_here

# Optional (leave empty for testing)
SUPABASE_URL=
SUPABASE_ANON_KEY=
```

**Windows:**
```powershell
copy .env.example .env
notepad .env
```

---

## ✅ Step 4: Run the App

```powershell
flutter run
```

**Enable location services when prompted!**

---

## 🎉 That's It!

Your disaster prediction app is now running with:
- ✅ Real-time weather data
- ✅ Earthquake monitoring  
- ✅ Wildfire tracking
- ✅ AI-powered risk predictions
- ✅ Interactive OpenStreetMap
- ✅ Smart alerts

---

## 🐛 Common Issues

### "Couldn't load .env"
```powershell
# Make sure .env exists in root directory
copy .env.example .env
```

### "API key invalid"
- OpenWeather: Wait 15 minutes after creating key
- Check for extra spaces in .env file

### "Location permission denied"
- **Android:** Settings → Apps → StormShield → Permissions → Location
- **iOS:** Settings → Privacy → Location → StormShield

### App crashes
```powershell
flutter clean
flutter pub get
flutter run
```

---

## 📚 Need More Help?

- **Detailed Setup:** See [SETUP.md](./SETUP.md)
- **Full Guide:** See [IMPLEMENTATION_GUIDE.md](./IMPLEMENTATION_GUIDE.md)
- **API Docs:** Each service has detailed documentation

---

## 🚀 Next Steps

1. **Test all features:** Navigate through Dashboard, Map, and Alerts
2. **Check different locations:** App uses your GPS location
3. **Monitor API usage:** Stay within free tier limits
4. **Customize:** Modify risk thresholds in services

---

**Ready to save lives? Let's go! 🌪️**
