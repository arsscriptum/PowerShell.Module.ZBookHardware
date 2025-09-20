-- Enable FK integrity and good defaults
PRAGMA foreign_keys = ON;
PRAGMA journal_mode  = WAL;

-- =========================
-- Core dimensions
-- =========================

-- Machines you collect from (host, VM, container, etc.)
CREATE TABLE IF NOT EXISTS hosts (
  host_id       INTEGER PRIMARY KEY,
  hostname      TEXT NOT NULL,
  machine_guid  TEXT,                -- optional stable ID if you have one
  created_at    INTEGER NOT NULL DEFAULT (unixepoch('now')),
  UNIQUE(hostname)
);

-- Optional logical grouping per run/collection window (use if you want to
-- bundle samples by job/execution; otherwise you can ignore this table).
CREATE TABLE IF NOT EXISTS sessions (
  session_id    INTEGER PRIMARY KEY,
  host_id       INTEGER NOT NULL REFERENCES hosts(host_id) ON DELETE CASCADE,
  source        TEXT,                -- e.g., "OpenHardwareMonitor", "WMI"
  version       TEXT,                -- data schema or tool version
  started_at    INTEGER NOT NULL DEFAULT (unixepoch('now')),
  note          TEXT
);

-- A sensor is a stable identity: (host + category + label + unit).
-- Examples:
--   category="Load",        label="CPU Core #2", unit="%"
--   category="Temperatures",label="CPU Package", unit="°C"
CREATE TABLE IF NOT EXISTS sensors (
  sensor_id     INTEGER PRIMARY KEY,
  host_id       INTEGER NOT NULL REFERENCES hosts(host_id) ON DELETE CASCADE,
  category      TEXT NOT NULL,       -- e.g., "Load", "Temperatures", "Fan", "Used Space"
  label         TEXT NOT NULL,       -- e.g., "CPU Total", "Memory", "GPU Core"
  unit          TEXT NOT NULL,       -- e.g., "%", "°C", "rpm", "GB"
  meta_json     TEXT,                -- optional: store original IDs/paths
  created_at    INTEGER NOT NULL DEFAULT (unixepoch('now')),
  last_seen_at  INTEGER,
  UNIQUE(host_id, category, label, unit)
);

CREATE INDEX IF NOT EXISTS ix_sensors_host ON sensors(host_id);
CREATE INDEX IF NOT EXISTS ix_sensors_cat_label ON sensors(category, label);

-- =========================
-- Fact table (time-series)
-- =========================

-- One row per observation.
-- 'value' is the instantaneous reading.
-- 'min_value'/'max_value' are whatever window your source reports (often since tool start);
-- keep them to mirror the source, but analytics should usually compute min/max over time from 'value'.
CREATE TABLE IF NOT EXISTS readings (
  reading_id    INTEGER PRIMARY KEY,
  sensor_id     INTEGER NOT NULL REFERENCES sensors(sensor_id) ON DELETE CASCADE,
  session_id    INTEGER REFERENCES sessions(session_id) ON DELETE SET NULL,
  collected_at  INTEGER NOT NULL,    -- unix epoch seconds
  value         REAL    NOT NULL,    -- e.g., 8.0
  min_value     REAL,                -- e.g., 0.0
  max_value     REAL,                -- e.g., 90.6
  source_raw    TEXT,                -- optional: raw line/JSON fragment
  CHECK (value IS NULL OR typeof(value) IN ('real','integer'))
);

CREATE INDEX IF NOT EXISTS ix_readings_sensor_time ON readings(sensor_id, collected_at DESC);
CREATE INDEX IF NOT EXISTS ix_readings_time ON readings(collected_at);

-- =========================
-- Helpers
-- =========================

-- Keep sensors.last_seen_at fresh when inserting readings
CREATE TRIGGER IF NOT EXISTS trg_readings_touch_sensor
AFTER INSERT ON readings
BEGIN
  UPDATE sensors
  SET last_seen_at = NEW.collected_at
  WHERE sensor_id = NEW.sensor_id;
END;

-- =========================
-- Convenience views
-- =========================

-- Latest reading per sensor (fast “current values” view)
CREATE VIEW IF NOT EXISTS vw_latest_readings AS
WITH latest AS (
  SELECT r.sensor_id, MAX(r.collected_at) AS max_ts
  FROM readings r
  GROUP BY r.sensor_id
)
SELECT s.sensor_id,
       s.host_id,
       s.category,
       s.label,
       s.unit,
       r.value,
       r.min_value,
       r.max_value,
       r.collected_at
FROM sensors s
JOIN latest  lt ON lt.sensor_id = s.sensor_id
JOIN readings r ON r.sensor_id = lt.sensor_id AND r.collected_at = lt.max_ts;

-- Recent CPU/GPU loads (example slice)
CREATE VIEW IF NOT EXISTS vw_recent_loads AS
SELECT s.label, r.value, r.collected_at
FROM sensors s
JOIN readings r ON r.sensor_id = s.sensor_id
WHERE s.category = 'Load' AND s.unit = '%';
