CREATE FUNCTION check_assignment_consistency() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE request_uuid uuid; current_stage text; active_count integer;
BEGIN
  IF TG_TABLE_NAME = 'relief_requests' THEN request_uuid := NEW.id;
  ELSE request_uuid := NEW.request_id;
  END IF;
  SELECT stage INTO current_stage FROM relief_requests WHERE id=request_uuid FOR UPDATE;
  SELECT count(*) INTO active_count FROM assignments WHERE request_id=request_uuid AND ended_at IS NULL;
  IF (current_stage='accepted' AND active_count<>1) OR (current_stage<>'accepted' AND active_count<>0) THEN
    RAISE EXCEPTION 'assignment and request state must be committed consistently' USING ERRCODE='23514';
  END IF;
  RETURN NULL;
END;
$$;
CREATE CONSTRAINT TRIGGER consistent_request_assignments AFTER INSERT OR UPDATE ON relief_requests
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION check_assignment_consistency();
CREATE CONSTRAINT TRIGGER consistent_assignment_requests AFTER INSERT OR UPDATE ON assignments
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION check_assignment_consistency();
