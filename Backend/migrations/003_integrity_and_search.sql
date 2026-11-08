CREATE FUNCTION immutable_assignment_identity() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.request_id<>OLD.request_id OR NEW.rescuer_id<>OLD.rescuer_id THEN
    RAISE EXCEPTION 'assignment identity is immutable' USING ERRCODE='23514';
  END IF;
  RETURN NEW;
END;
$$;
CREATE TRIGGER immutable_assignment_identity BEFORE UPDATE ON assignments
FOR EACH ROW EXECUTE FUNCTION immutable_assignment_identity();

CREATE OR REPLACE FUNCTION check_assignment_consistency() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE request_uuid uuid; current_stage text; active_count integer;
BEGIN
  IF TG_TABLE_NAME='relief_requests' THEN request_uuid:=NEW.id;
  ELSIF TG_OP='DELETE' THEN request_uuid:=OLD.request_id;
  ELSE request_uuid:=NEW.request_id;
  END IF;
  SELECT stage INTO current_stage FROM relief_requests WHERE id=request_uuid FOR UPDATE;
  IF NOT FOUND THEN RETURN NULL; END IF;
  SELECT count(*) INTO active_count FROM assignments WHERE request_id=request_uuid AND ended_at IS NULL;
  IF (current_stage='accepted' AND active_count<>1) OR (current_stage<>'accepted' AND active_count<>0) THEN
    RAISE EXCEPTION 'assignment and request state must be committed consistently' USING ERRCODE='23514';
  END IF;
  RETURN NULL;
END;
$$;
DROP TRIGGER consistent_assignment_requests ON assignments;
CREATE CONSTRAINT TRIGGER consistent_assignment_requests AFTER INSERT OR UPDATE OR DELETE ON assignments
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION check_assignment_consistency();
ALTER TABLE relief_requests ADD COLUMN search_document tsvector
GENERATED ALWAYS AS (to_tsvector('simple',data->>'description')) STORED;
CREATE INDEX relief_request_content_search ON relief_requests USING gin(search_document);
CREATE INDEX request_history_page ON request_history(request_id,id DESC);
