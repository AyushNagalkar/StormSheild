-- Shelters Table
CREATE TABLE IF NOT EXISTS shelters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    address TEXT NOT NULL,
    district TEXT NOT NULL,
    village TEXT,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    capacity INTEGER NOT NULL,
    current_occupancy INTEGER DEFAULT 0,
    shelter_type TEXT NOT NULL, -- 'government', 'school', 'community_center', 'temporary'
    facilities TEXT[], -- ['water', 'electricity', 'medical', 'food', 'blankets']
    contact_number TEXT,
    manager_name TEXT,
    is_active BOOLEAN DEFAULT true,
    disaster_types TEXT[], -- ['flood', 'cyclone', 'earthquake', 'wildfire', 'heatwave']
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable PostGIS for geographic queries
CREATE EXTENSION IF NOT EXISTS postgis;

-- Add geography column for better distance calculations
ALTER TABLE shelters ADD COLUMN IF NOT EXISTS location GEOGRAPHY(POINT, 4326);

-- Update location column from lat/lon
UPDATE shelters SET location = ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography;

-- Create index for fast geographic queries
CREATE INDEX IF NOT EXISTS shelters_location_idx ON shelters USING GIST(location);
CREATE INDEX IF NOT EXISTS shelters_district_idx ON shelters(district);
CREATE INDEX IF NOT EXISTS shelters_active_idx ON shelters(is_active);

-- Districts Table for risk visualization
CREATE TABLE IF NOT EXISTS districts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    state TEXT NOT NULL,
    country TEXT DEFAULT 'India',
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    population INTEGER,
    area_sq_km DOUBLE PRECISION,
    boundary GEOGRAPHY(POLYGON, 4326),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS districts_name_idx ON districts(name);
CREATE INDEX IF NOT EXISTS districts_boundary_idx ON districts USING GIST(boundary);

-- Villages Table
CREATE TABLE IF NOT EXISTS villages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    district_id UUID REFERENCES districts(id),
    district_name TEXT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    population INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS villages_district_idx ON villages(district_id);
CREATE INDEX IF NOT EXISTS villages_name_idx ON villages(name);

-- Real-time Risk Data Table
CREATE TABLE IF NOT EXISTS risk_zones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    district_name TEXT NOT NULL,
    village_name TEXT,
    disaster_type TEXT NOT NULL,
    risk_level DOUBLE PRECISION NOT NULL, -- 0.0 to 1.0
    severity TEXT NOT NULL, -- 'low', 'medium', 'high', 'critical'
    active_alerts INTEGER DEFAULT 0,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    metadata JSONB -- Additional risk data
);

CREATE INDEX IF NOT EXISTS risk_zones_district_idx ON risk_zones(district_name);
CREATE INDEX IF NOT EXISTS risk_zones_disaster_idx ON risk_zones(disaster_type);
CREATE INDEX IF NOT EXISTS risk_zones_severity_idx ON risk_zones(severity);

-- User Saved Locations Table
CREATE TABLE IF NOT EXISTS user_locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL, -- Can be device ID for anonymous users
    location_name TEXT NOT NULL,
    address TEXT,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    is_primary BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS user_locations_user_idx ON user_locations(user_id);

-- Emergency Resources Table
CREATE TABLE IF NOT EXISTS emergency_resources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shelter_id UUID REFERENCES shelters(id),
    resource_type TEXT NOT NULL, -- 'food', 'water', 'medical', 'blankets', 'generator'
    quantity INTEGER NOT NULL,
    unit TEXT NOT NULL, -- 'liters', 'kg', 'pieces', 'sets'
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS resources_shelter_idx ON emergency_resources(shelter_id);

-- Function to find nearest shelters
CREATE OR REPLACE FUNCTION find_nearest_shelters(
    user_lat DOUBLE PRECISION,
    user_lon DOUBLE PRECISION,
    max_distance_km DOUBLE PRECISION DEFAULT 50,
    limit_count INTEGER DEFAULT 10
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    address TEXT,
    district TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    distance_km DOUBLE PRECISION,
    capacity INTEGER,
    current_occupancy INTEGER,
    available_space INTEGER,
    shelter_type TEXT,
    facilities TEXT[],
    contact_number TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id,
        s.name,
        s.address,
        s.district,
        s.latitude,
        s.longitude,
        ST_Distance(
            s.location,
            ST_SetSRID(ST_MakePoint(user_lon, user_lat), 4326)::geography
        ) / 1000 AS distance_km,
        s.capacity,
        s.current_occupancy,
        (s.capacity - s.current_occupancy) AS available_space,
        s.shelter_type,
        s.facilities,
        s.contact_number
    FROM shelters s
    WHERE s.is_active = true
        AND ST_Distance(
            s.location,
            ST_SetSRID(ST_MakePoint(user_lon, user_lat), 4326)::geography
        ) / 1000 <= max_distance_km
    ORDER BY distance_km
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- Sample shelter data (modify with real data)
INSERT INTO shelters (name, address, district, village, latitude, longitude, capacity, shelter_type, facilities, contact_number, disaster_types)
VALUES 
    ('Government Primary School Shelter', 'Main Road, Village Center', 'Sample District', 'Sample Village', 28.6139, 77.2090, 500, 'school', ARRAY['water', 'electricity', 'medical', 'food'], '+91-1234567890', ARRAY['flood', 'cyclone', 'earthquake']),
    ('Community Center Shelter', 'Community Hall Road', 'Sample District', 'Sample Village', 28.6239, 77.2190, 300, 'community_center', ARRAY['water', 'food', 'blankets'], '+91-1234567891', ARRAY['flood', 'cyclone', 'heatwave']),
    ('District Emergency Relief Center', 'District HQ Compound', 'Sample District', NULL, 28.6339, 77.2290, 1000, 'government', ARRAY['water', 'electricity', 'medical', 'food', 'blankets'], '+91-1234567892', ARRAY['flood', 'cyclone', 'earthquake', 'wildfire', 'heatwave'])
ON CONFLICT DO NOTHING;

-- Update location geography column
UPDATE shelters SET location = ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography WHERE location IS NULL;

-- Enable Row Level Security (RLS)
ALTER TABLE shelters ENABLE ROW LEVEL SECURITY;
ALTER TABLE districts ENABLE ROW LEVEL SECURITY;
ALTER TABLE villages ENABLE ROW LEVEL SECURITY;
ALTER TABLE risk_zones ENABLE ROW LEVEL SECURITY;
ALTER TABLE emergency_resources ENABLE ROW LEVEL SECURITY;

-- Create policies for public read access
CREATE POLICY "Enable read access for all users" ON shelters FOR SELECT USING (true);
CREATE POLICY "Enable read access for all users" ON districts FOR SELECT USING (true);
CREATE POLICY "Enable read access for all users" ON villages FOR SELECT USING (true);
CREATE POLICY "Enable read access for all users" ON risk_zones FOR SELECT USING (true);
CREATE POLICY "Enable read access for all users" ON emergency_resources FOR SELECT USING (true);
