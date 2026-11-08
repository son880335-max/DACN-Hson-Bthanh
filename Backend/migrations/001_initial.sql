CREATE TABLE accounts (
  id uuid PRIMARY KEY,
  phone text NOT NULL UNIQUE,
  display_name text NOT NULL,
  password_hash text NOT NULL,
  role text NOT NULL CHECK (role IN ('citizen', 'rescue', 'admin')),
  permissions text[] NOT NULL DEFAULT '{}',
  phone_verified_at timestamptz,
  locked_at timestamptz,
  team_approved boolean NOT NULL DEFAULT false,
  is_test_account boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT clock_timestamp()
);

CREATE TABLE sessions (
  token_hash text PRIMARY KEY,
  account_id uuid NOT NULL REFERENCES accounts(id),
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  expires_at timestamptz NOT NULL,
  revoked_at timestamptz
);
CREATE INDEX sessions_account_idx ON sessions(account_id);

CREATE TABLE relief_requests (
  id uuid PRIMARY KEY,
  owner_id uuid NOT NULL REFERENCES accounts(id),
  stage text NOT NULL DEFAULT 'waiting' CHECK (stage IN ('waiting', 'accepted', 'completed', 'cancelled')),
  verification text NOT NULL DEFAULT 'pending' CHECK (verification IN ('pending', 'valid', 'needs_info', 'invalid')),
  revision integer NOT NULL DEFAULT 1 CHECK (revision > 0),
  data jsonb NOT NULL,
  latitude double precision NOT NULL CHECK (latitude >= -90 AND latitude <= 90),
  longitude double precision NOT NULL CHECK (longitude >= -180 AND longitude <= 180),
  client_action_at timestamptz NOT NULL,
  received_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  updated_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  cancelled_at timestamptz,
  review_reason text NOT NULL DEFAULT '',
  CHECK ((stage = 'cancelled') = (cancelled_at IS NOT NULL))
);
CREATE UNIQUE INDEX one_open_request_per_owner ON relief_requests(owner_id)
  WHERE stage IN ('waiting', 'accepted');
CREATE INDEX requests_owner_page_idx ON relief_requests(owner_id, created_at DESC, id DESC);
CREATE INDEX requests_review_idx ON relief_requests(verification, created_at DESC);
CREATE INDEX requests_location_idx ON relief_requests(latitude, longitude);

CREATE TABLE assignments (
  id uuid PRIMARY KEY,
  request_id uuid NOT NULL REFERENCES relief_requests(id),
  rescuer_id uuid NOT NULL REFERENCES accounts(id),
  accepted_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  ended_at timestamptz
);
CREATE UNIQUE INDEX one_active_assignment ON assignments(request_id) WHERE ended_at IS NULL;
CREATE INDEX assignments_rescuer_idx ON assignments(rescuer_id, request_id) WHERE ended_at IS NULL;

CREATE TABLE evidence (
  id uuid PRIMARY KEY,
  owner_id uuid NOT NULL REFERENCES accounts(id),
  request_id uuid REFERENCES relief_requests(id),
  storage_key text NOT NULL UNIQUE,
  sha256 text NOT NULL,
  byte_length integer NOT NULL CHECK (byte_length > 0),
  captured_at timestamptz NOT NULL,
  latitude double precision,
  longitude double precision,
  received_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  CHECK (latitude IS NULL OR (latitude >= -90 AND latitude <= 90)),
  CHECK (longitude IS NULL OR (longitude >= -180 AND longitude <= 180))
);
CREATE INDEX evidence_request_idx ON evidence(request_id);

CREATE TABLE request_history (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  request_id uuid NOT NULL REFERENCES relief_requests(id),
  actor_id uuid NOT NULL REFERENCES accounts(id),
  action text NOT NULL,
  revision integer NOT NULL,
  details jsonb NOT NULL DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
CREATE INDEX request_history_request_idx ON request_history(request_id, id);

CREATE FUNCTION protect_request_history() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN RAISE EXCEPTION 'request_history is append only'; END;
$$;
CREATE TRIGGER immutable_request_history BEFORE UPDATE OR DELETE ON request_history
FOR EACH ROW EXECUTE FUNCTION protect_request_history();

CREATE TABLE fraud_reports (
  id uuid PRIMARY KEY,
  request_id uuid NOT NULL REFERENCES relief_requests(id),
  reporter_id uuid NOT NULL REFERENCES accounts(id),
  reason text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
CREATE INDEX fraud_reports_request_idx ON fraud_reports(request_id, created_at);

CREATE TABLE notices (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  account_id uuid NOT NULL REFERENCES accounts(id),
  request_id uuid NOT NULL REFERENCES relief_requests(id),
  kind text NOT NULL,
  message text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  read_at timestamptz
);
CREATE INDEX notices_account_idx ON notices(account_id, id DESC);

CREATE TABLE operation_receipts (
  actor_id uuid NOT NULL REFERENCES accounts(id),
  operation_id uuid NOT NULL,
  kind text NOT NULL,
  body_hash text NOT NULL,
  response jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  PRIMARY KEY (actor_id, operation_id)
);
