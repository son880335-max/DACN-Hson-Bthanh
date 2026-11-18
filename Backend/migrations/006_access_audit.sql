CREATE TABLE access_audit (
  id uuid PRIMARY KEY,
  actor_id uuid NOT NULL REFERENCES accounts(id),
  request_id uuid NOT NULL REFERENCES relief_requests(id),
  kind text NOT NULL,
  at timestamptz NOT NULL DEFAULT clock_timestamp()
);

CREATE INDEX access_audit_rate_idx ON access_audit(actor_id, request_id, at DESC);
