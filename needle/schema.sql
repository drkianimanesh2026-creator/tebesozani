PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS needle_users (
  id TEXT PRIMARY KEY,
  full_name TEXT NOT NULL,
  phone TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  role TEXT NOT NULL CHECK(role IN ('admin','teacher','student')),
  active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS needle_sessions (
  token_hash TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES needle_users(id) ON DELETE CASCADE,
  expires_at TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS needle_settings (
  id INTEGER PRIMARY KEY CHECK(id=1),
  commission_percent REAL NOT NULL DEFAULT 10 CHECK(commission_percent >= 0 AND commission_percent <= 100),
  payment_mode TEXT NOT NULL DEFAULT 'both' CHECK(payment_mode IN ('teacher','institute','both')),
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
INSERT OR IGNORE INTO needle_settings (id, commission_percent, payment_mode) VALUES (1, 10, 'both');

CREATE TABLE IF NOT EXISTS needle_orders (
  id TEXT PRIMARY KEY,
  order_code TEXT NOT NULL UNIQUE,
  student_id TEXT NOT NULL REFERENCES needle_users(id),
  teacher_id TEXT NOT NULL REFERENCES needle_users(id),
  course_name TEXT,
  product_name TEXT NOT NULL DEFAULT 'سوزن',
  quantity INTEGER NOT NULL CHECK(quantity > 0),
  unit_price INTEGER NOT NULL CHECK(unit_price >= 0),
  total_amount INTEGER NOT NULL CHECK(total_amount >= 0),
  commission_percent REAL NOT NULL,
  institute_share INTEGER NOT NULL,
  payment_destination TEXT NOT NULL CHECK(payment_destination IN ('teacher','institute')),
  status TEXT NOT NULL DEFAULT 'pending_payment',
  notes TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS needle_payments (
  id TEXT PRIMARY KEY,
  order_id TEXT NOT NULL REFERENCES needle_orders(id) ON DELETE CASCADE,
  amount INTEGER NOT NULL CHECK(amount > 0),
  destination TEXT NOT NULL CHECK(destination IN ('teacher','institute')),
  reference TEXT,
  receipt_url TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','approved','rejected')),
  recorded_by TEXT NOT NULL REFERENCES needle_users(id),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS needle_purchases (
  id TEXT PRIMARY KEY,
  teacher_id TEXT NOT NULL REFERENCES needle_users(id),
  order_id TEXT REFERENCES needle_orders(id),
  quantity INTEGER NOT NULL CHECK(quantity > 0),
  total_cost INTEGER NOT NULL CHECK(total_cost >= 0),
  supplier TEXT,
  invoice_ref TEXT,
  notes TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS needle_settlements (
  id TEXT PRIMARY KEY,
  teacher_id TEXT NOT NULL REFERENCES needle_users(id),
  amount INTEGER NOT NULL CHECK(amount > 0),
  reference TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','approved','rejected')),
  recorded_by TEXT NOT NULL REFERENCES needle_users(id),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS needle_audit (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  actor_id TEXT,
  action TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id TEXT,
  details TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_needle_orders_student ON needle_orders(student_id, created_at);
CREATE INDEX IF NOT EXISTS idx_needle_orders_teacher ON needle_orders(teacher_id, created_at);
CREATE INDEX IF NOT EXISTS idx_needle_payments_order ON needle_payments(order_id);
CREATE INDEX IF NOT EXISTS idx_needle_sessions_expiry ON needle_sessions(expires_at);
