# 🚀 Quick Setup Guide - Shelter System

## Step 1: Set Up Supabase Database (5 minutes)

### 1.1 Create/Login to Supabase Project
1. Go to https://supabase.com
2. Sign in (or create account - FREE)
3. Create new project or select existing
4. Wait for project to initialize

### 1.2 Run Database Schema

**Option A: Using SQL Editor (Recommended)**
1. Open your Supabase project
2. Click **SQL Editor** in sidebar
3. Click **New Query**
4. Copy entire contents of `database/shelters_schema.sql`
5. Paste into editor
6. Click **Run** button
7. Wait for "Success" message

**Option B: Using psql (Advanced)**
```bash
psql -h db.your-project.supabase.co -U postgres -d postgres -f database/shelters_schema.sql
```

### 1.3 Verify Installation

Run this query in SQL Editor:
```sql
SELECT COUNT(*) FROM shelters;
```
Should return 3 (sample shelters)

```sql
SELECT * FROM shelters LIMIT 5;
```
Should show shelter data

## Step 2: Configure App (2 minutes)

### 2.1 Get Supabase Credentials

In Supabase Dashboard:
1. Click **Settings** (gear icon)
2. Click **API**
3. Copy **Project URL**
4. Copy **anon/public** key

### 2.2 Update .env File

```env
# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key_here

# Other APIs (already configured)
NASA_FIRMS_API_KEY=your_key
GEMINI_API_KEY=your_key
```

### 2.3 Test Connection

Run app:
```bash
flutter run -d chrome
```

Click shelter icon 🏠 - should show 3 sample shelters!

## Step 3: Add Real Shelter Data (10 minutes)

### 3.1 Prepare Shelter Data

Create a list of real shelters in your area. For each shelter, collect:
- Name
- Full address
- District name
- Village name (if applicable)
- GPS coordinates (use Google Maps)
- Capacity (max people)
- Shelter type (government/school/community_center/temporary)
- Available facilities (water, electricity, medical, food, blankets)
- Contact phone number
- Manager name

### 3.2 Insert Shelters

In Supabase SQL Editor:

```sql
-- Add your first real shelter
INSERT INTO shelters (
  name, 
  address, 
  district, 
  village,
  latitude, 
  longitude, 
  capacity,
  shelter_type,
  facilities,
  contact_number,
  manager_name,
  disaster_types
) VALUES (
  'Community High School Emergency Shelter',           -- name
  'Block A, Main Road, Near Police Station',          -- address
  'Mumbai District',                                    -- district
  'Andheri West',                                      -- village
  19.1334,                                             -- latitude
  72.8255,                                             -- longitude
  800,                                                 -- capacity
  'school',                                            -- type
  ARRAY['water', 'electricity', 'medical', 'food'],   -- facilities
  '+91-22-12345678',                                   -- contact
  'Mr. Sharma',                                        -- manager
  ARRAY['flood', 'cyclone', 'earthquake']             -- disaster types
);

-- Update geography column (IMPORTANT!)
UPDATE shelters 
SET location = ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography 
WHERE location IS NULL;
```

### 3.3 Bulk Insert (For Many Shelters)

```sql
INSERT INTO shelters (name, address, district, village, latitude, longitude, capacity, shelter_type, facilities, contact_number, disaster_types)
VALUES 
  ('Shelter 1', 'Address 1', 'District 1', NULL, 19.1334, 72.8255, 500, 'government', ARRAY['water', 'medical'], '+91-1234567890', ARRAY['flood', 'cyclone']),
  ('Shelter 2', 'Address 2', 'District 2', 'Village 2', 19.1434, 72.8355, 300, 'school', ARRAY['water', 'food'], '+91-1234567891', ARRAY['earthquake']),
  ('Shelter 3', 'Address 3', 'District 3', NULL, 19.1534, 72.8455, 1000, 'community_center', ARRAY['water', 'electricity', 'medical', 'food'], '+91-1234567892', ARRAY['flood', 'cyclone', 'heatwave']);

-- Don't forget to update geography!
UPDATE shelters 
SET location = ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography 
WHERE location IS NULL;
```

## Step 4: Add Districts & Villages (Optional, 5 minutes)

### 4.1 Add Districts

```sql
INSERT INTO districts (name, state, latitude, longitude, population)
VALUES 
  ('Mumbai', 'Maharashtra', 19.0760, 72.8777, 12442373),
  ('Delhi', 'Delhi', 28.7041, 77.1025, 16787941),
  ('Bangalore', 'Karnataka', 12.9716, 77.5946, 8443675);
```

### 4.2 Add Villages/Localities

```sql
INSERT INTO villages (name, district_name, latitude, longitude, population)
VALUES 
  ('Andheri West', 'Mumbai', 19.1334, 72.8255, 389000),
  ('Bandra', 'Mumbai', 19.0596, 72.8295, 226000),
  ('Connaught Place', 'Delhi', 28.6315, 77.2167, 50000);
```

## Step 5: Test Everything (3 minutes)

### 5.1 Test Location Selection
1. Open app
2. Click location icon 📍
3. Try "Use Current Location" (allow GPS)
4. Try searching for a city
5. Try selecting from district dropdown

### 5.2 Test Shelter Finder
1. Click shelter icon 🏠
2. Should see list of nearby shelters
3. Click a shelter card
4. View details (capacity, facilities, etc.)
5. Click "Get Directions" (opens Google Maps)
6. Click "Call" to test phone dial

### 5.3 Test Manual Location
1. Click location icon 📍
2. Search for "Mumbai" or your city
3. Click "Use This"
4. Dashboard should update with new location data
5. Shelter list should refresh with nearby shelters

## 🎉 You're Done!

Your StormShield app now has:
✅ Emergency shelter database
✅ Location selection (GPS, search, districts)
✅ Safe route planning
✅ Real-time capacity tracking
✅ Contact information
✅ Distance calculations

## 🔧 Troubleshooting

### Problem: Shelters not showing
**Solution:**
1. Check Supabase connection (URL and key in .env)
2. Verify schema installed (run queries in Step 1.3)
3. Update geography column (see Step 3.2)
4. Check app logs for errors

### Problem: Location search not working
**Solution:**
1. Ensure geocoding package installed: `flutter pub get`
2. Check internet connection
3. Try entering more specific address

### Problem: "No shelters nearby"
**Solution:**
1. Add more shelters in database
2. Increase search radius (modify `maxDistanceKm` in code)
3. Check shelter coordinates are correct
4. Verify PostGIS extension enabled

### Problem: Database errors
**Solution:**
```sql
-- Check if PostGIS is enabled
SELECT PostGIS_version();

-- If not, enable it
CREATE EXTENSION IF NOT EXISTS postgis;

-- Recreate indexes
DROP INDEX IF EXISTS shelters_location_idx;
CREATE INDEX shelters_location_idx ON shelters USING GIST(location);
```

### Problem: Navigation not working
**Solution:**
- Ensure Google Maps app installed (mobile)
- Check URL launcher permissions
- Try opening maps manually first

## 📚 Next Steps

1. **Add More Shelters**: Collect real data from:
   - Government disaster management offices
   - School/college administrators
   - Community centers
   - NGOs and relief organizations

2. **Update Regularly**: Keep capacity and contact info current

3. **Test in Field**: Try during actual drills or exercises

4. **Gather Feedback**: Let users report issues

5. **Expand Coverage**: Add shelters in surrounding districts

## 💡 Pro Tips

### Getting GPS Coordinates
1. Open Google Maps
2. Right-click location
3. Click on coordinates to copy
4. Paste into database

### Bulk Data Entry
1. Create CSV file with shelter data
2. Use Supabase Dashboard → Table Editor
3. Click "Insert" → "Insert from CSV"
4. Map columns and import

### Validation
```sql
-- Find shelters with missing geography
SELECT * FROM shelters WHERE location IS NULL;

-- Fix them
UPDATE shelters 
SET location = ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography 
WHERE location IS NULL;
```

### Performance
```sql
-- Check index usage
EXPLAIN ANALYZE 
SELECT * FROM shelters 
WHERE ST_Distance(
  location, 
  ST_SetSRID(ST_MakePoint(77.2090, 28.6139), 4326)::geography
) / 1000 <= 50;

-- Should show "Index Scan using shelters_location_idx"
```

## 🆘 Support

- Documentation: `SHELTER_SYSTEM.md`
- Schema file: `database/shelters_schema.sql`
- Issues: Check app logs
- Questions: Review IMPLEMENTATION_GUIDE.md

**Your disaster response system is now fully operational!** 🚀
