-- Migration: Create Device Resolutions System
-- Description: System for managing mobile/tablet device resolutions for page builder
-- Author: AI Assistant
-- Date: 2025-10-09

-- Create schema for page builder settings
CREATE SCHEMA IF NOT EXISTS page_builder;

-- Create device_resolutions table
CREATE TABLE IF NOT EXISTS page_builder.device_resolutions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_key VARCHAR(100) UNIQUE NOT NULL,
  device_name VARCHAR(200) NOT NULL,
  device_type VARCHAR(50) NOT NULL CHECK (device_type IN ('mobile', 'tablet', 'desktop')),
  width_px INTEGER NOT NULL,
  height_px INTEGER,
  label VARCHAR(200) NOT NULL,
  manufacturer VARCHAR(100),
  model VARCHAR(100),
  release_year INTEGER,
  is_active BOOLEAN DEFAULT true,
  is_default BOOLEAN DEFAULT false,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  created_by UUID,
  updated_by UUID
);

-- Create index on device_type and is_active for fast filtering
CREATE INDEX idx_device_resolutions_type_active ON page_builder.device_resolutions(device_type, is_active);
CREATE INDEX idx_device_resolutions_order ON page_builder.device_resolutions(display_order);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION page_builder.update_device_resolutions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_device_resolutions_updated_at
  BEFORE UPDATE ON page_builder.device_resolutions
  FOR EACH ROW
  EXECUTE FUNCTION page_builder.update_device_resolutions_updated_at();

-- Seed with current popular mobile devices (2024-2025)
INSERT INTO page_builder.device_resolutions (device_key, device_name, device_type, width_px, height_px, label, manufacturer, model, release_year, is_default, display_order) VALUES
  -- iPhone devices
  ('iphone-se', 'iPhone SE (3rd gen)', 'mobile', 375, 667, 'iPhone SE (375px)', 'Apple', 'iPhone SE', 2022, false, 10),
  ('iphone-13-mini', 'iPhone 13 mini', 'mobile', 375, 812, 'iPhone 13 mini (375px)', 'Apple', 'iPhone 13 mini', 2021, false, 20),
  ('iphone-13', 'iPhone 13/14', 'mobile', 390, 844, 'iPhone 13/14 (390px)', 'Apple', 'iPhone 13', 2021, true, 30),
  ('iphone-14-plus', 'iPhone 14 Plus', 'mobile', 428, 926, 'iPhone 14 Plus (428px)', 'Apple', 'iPhone 14 Plus', 2022, false, 40),
  ('iphone-14-pro', 'iPhone 14 Pro', 'mobile', 393, 852, 'iPhone 14 Pro (393px)', 'Apple', 'iPhone 14 Pro', 2022, false, 50),
  ('iphone-14-pro-max', 'iPhone 14 Pro Max', 'mobile', 430, 932, 'iPhone 14 Pro Max (430px)', 'Apple', 'iPhone 14 Pro Max', 2022, false, 60),
  ('iphone-15', 'iPhone 15', 'mobile', 393, 852, 'iPhone 15 (393px)', 'Apple', 'iPhone 15', 2023, false, 70),
  ('iphone-15-plus', 'iPhone 15 Plus', 'mobile', 430, 932, 'iPhone 15 Plus (430px)', 'Apple', 'iPhone 15 Plus', 2023, false, 80),
  ('iphone-15-pro', 'iPhone 15 Pro', 'mobile', 393, 852, 'iPhone 15 Pro (393px)', 'Apple', 'iPhone 15 Pro', 2023, false, 90),
  ('iphone-15-pro-max', 'iPhone 15 Pro Max', 'mobile', 430, 932, 'iPhone 15 Pro Max (430px)', 'Apple', 'iPhone 15 Pro Max', 2023, false, 100),
  ('iphone-16', 'iPhone 16', 'mobile', 393, 852, 'iPhone 16 (393px)', 'Apple', 'iPhone 16', 2024, false, 110),
  ('iphone-16-plus', 'iPhone 16 Plus', 'mobile', 430, 932, 'iPhone 16 Plus (430px)', 'Apple', 'iPhone 16 Plus', 2024, false, 120),
  ('iphone-16-pro', 'iPhone 16 Pro', 'mobile', 402, 874, 'iPhone 16 Pro (402px)', 'Apple', 'iPhone 16 Pro', 2024, false, 130),
  ('iphone-16-pro-max', 'iPhone 16 Pro Max', 'mobile', 440, 956, 'iPhone 16 Pro Max (440px)', 'Apple', 'iPhone 16 Pro Max', 2024, false, 140),
  ('iphone-17', 'iPhone 17', 'mobile', 402, 874, 'iPhone 17 (402px)', 'Apple', 'iPhone 17', 2025, false, 150),
  ('iphone-17-pro', 'iPhone 17 Pro', 'mobile', 402, 874, 'iPhone 17 Pro (402px)', 'Apple', 'iPhone 17 Pro', 2025, false, 160),

  -- Samsung Galaxy devices
  ('samsung-s21', 'Samsung Galaxy S21', 'mobile', 360, 800, 'Samsung S21 (360px)', 'Samsung', 'Galaxy S21', 2021, false, 200),
  ('samsung-s22', 'Samsung Galaxy S22', 'mobile', 360, 800, 'Samsung S22 (360px)', 'Samsung', 'Galaxy S22', 2022, false, 210),
  ('samsung-s23', 'Samsung Galaxy S23', 'mobile', 360, 780, 'Samsung S23 (360px)', 'Samsung', 'Galaxy S23', 2023, false, 220),
  ('samsung-s24', 'Samsung Galaxy S24', 'mobile', 360, 780, 'Samsung S24 (360px)', 'Samsung', 'Galaxy S24', 2024, false, 230),
  ('samsung-s24-ultra', 'Samsung Galaxy S24 Ultra', 'mobile', 384, 832, 'Samsung S24 Ultra (384px)', 'Samsung', 'Galaxy S24 Ultra', 2024, false, 240),

  -- Google Pixel devices
  ('pixel-5', 'Google Pixel 5', 'mobile', 393, 851, 'Pixel 5 (393px)', 'Google', 'Pixel 5', 2020, false, 300),
  ('pixel-6', 'Google Pixel 6', 'mobile', 412, 915, 'Pixel 6 (412px)', 'Google', 'Pixel 6', 2021, false, 310),
  ('pixel-7', 'Google Pixel 7', 'mobile', 412, 915, 'Pixel 7 (412px)', 'Google', 'Pixel 7', 2022, false, 320),
  ('pixel-8', 'Google Pixel 8', 'mobile', 412, 915, 'Pixel 8 (412px)', 'Google', 'Pixel 8', 2023, false, 330),
  ('pixel-8-pro', 'Google Pixel 8 Pro', 'mobile', 448, 998, 'Pixel 8 Pro (448px)', 'Google', 'Pixel 8 Pro', 2023, false, 340),
  ('pixel-9', 'Google Pixel 9', 'mobile', 412, 915, 'Pixel 9 (412px)', 'Google', 'Pixel 9', 2024, false, 350),

  -- Xiaomi devices
  ('xiaomi-redmi-note-12', 'Xiaomi Redmi Note 12', 'mobile', 393, 873, 'Redmi Note 12 (393px)', 'Xiaomi', 'Redmi Note 12', 2023, false, 400),
  ('xiaomi-14', 'Xiaomi 14', 'mobile', 392, 872, 'Xiaomi 14 (392px)', 'Xiaomi', 'Xiaomi 14', 2024, false, 410),

  -- OnePlus devices
  ('oneplus-11', 'OnePlus 11', 'mobile', 412, 919, 'OnePlus 11 (412px)', 'OnePlus', 'OnePlus 11', 2023, false, 500),
  ('oneplus-12', 'OnePlus 12', 'mobile', 412, 919, 'OnePlus 12 (412px)', 'OnePlus', 'OnePlus 12', 2024, false, 510),

  -- Generic/Common resolutions
  ('mobile-small', 'Small Mobile', 'mobile', 320, 568, 'Small Mobile (320px)', NULL, NULL, NULL, false, 900),
  ('mobile-medium', 'Medium Mobile', 'mobile', 375, 667, 'Medium Mobile (375px)', NULL, NULL, NULL, false, 910),
  ('mobile-large', 'Large Mobile', 'mobile', 414, 896, 'Large Mobile (414px)', NULL, NULL, NULL, false, 920),

  -- Tablets
  ('ipad-mini', 'iPad mini', 'tablet', 744, 1133, 'iPad mini (744px)', 'Apple', 'iPad mini', 2021, false, 1000),
  ('ipad-air', 'iPad Air', 'tablet', 820, 1180, 'iPad Air (820px)', 'Apple', 'iPad Air', 2022, false, 1010),
  ('ipad-pro-11', 'iPad Pro 11"', 'tablet', 834, 1194, 'iPad Pro 11" (834px)', 'Apple', 'iPad Pro 11"', 2024, true, 1020),
  ('ipad-pro-13', 'iPad Pro 13"', 'tablet', 1024, 1366, 'iPad Pro 13" (1024px)', 'Apple', 'iPad Pro 13"', 2024, false, 1030),
  ('samsung-tab-s9', 'Samsung Tab S9', 'tablet', 800, 1280, 'Samsung Tab S9 (800px)', 'Samsung', 'Galaxy Tab S9', 2023, false, 1100),
  ('tablet-generic', 'Generic Tablet', 'tablet', 768, 1024, 'Generic Tablet (768px)', NULL, NULL, NULL, false, 1200)
ON CONFLICT (device_key) DO NOTHING;

-- Create view for active devices grouped by type
CREATE OR REPLACE VIEW page_builder.v_device_resolutions_active AS
SELECT
  id,
  device_key,
  device_name,
  device_type,
  width_px,
  height_px,
  label,
  manufacturer,
  model,
  release_year,
  is_default,
  display_order
FROM page_builder.device_resolutions
WHERE is_active = true
ORDER BY device_type, display_order;

COMMENT ON TABLE page_builder.device_resolutions IS 'Stores device resolutions for page builder viewport testing';
COMMENT ON COLUMN page_builder.device_resolutions.device_key IS 'Unique identifier key for the device (e.g., iphone-17-pro)';
COMMENT ON COLUMN page_builder.device_resolutions.device_type IS 'Type of device: mobile, tablet, or desktop';
COMMENT ON COLUMN page_builder.device_resolutions.width_px IS 'Device width in pixels (viewport width)';
COMMENT ON COLUMN page_builder.device_resolutions.height_px IS 'Device height in pixels (viewport height) - optional';
COMMENT ON COLUMN page_builder.device_resolutions.label IS 'Human-readable label shown in UI';
COMMENT ON COLUMN page_builder.device_resolutions.is_default IS 'Whether this is the default device for its type';
COMMENT ON COLUMN page_builder.device_resolutions.display_order IS 'Order in which devices appear in dropdown';
