-- Run this once in the Cloudflare D1 database console.
-- Only aggregate daily counts are stored. No IP addresses or personal identifiers are retained.
CREATE TABLE IF NOT EXISTS site_stats (
  id TEXT PRIMARY KEY,
  total_count INTEGER NOT NULL DEFAULT 0
);

INSERT OR IGNORE INTO site_stats (id, total_count) VALUES ('all', 0);

CREATE TABLE IF NOT EXISTS daily_visits (
  visit_day TEXT PRIMARY KEY,
  visit_count INTEGER NOT NULL DEFAULT 0
);
