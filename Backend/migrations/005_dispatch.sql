ALTER TABLE assignments ADD COLUMN progress text NOT NULL DEFAULT 'accepted'
  CHECK (progress IN ('accepted','travelling','arrived'));
ALTER TABLE relief_requests ADD COLUMN primary_request_id uuid REFERENCES relief_requests(id);
ALTER TABLE relief_requests ADD CHECK (primary_request_id IS DISTINCT FROM id);
CREATE INDEX linked_requests_idx ON relief_requests(primary_request_id) WHERE primary_request_id IS NOT NULL;

-- Existing request mutations share the dispatch lifecycle without changing their API.
CREATE FUNCTION check_linked_request_edit() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE primary_stage text;
BEGIN
  IF OLD.primary_request_id IS NOT NULL AND (NEW.stage='cancelled' OR NEW.data IS DISTINCT FROM OLD.data) THEN
    SELECT stage INTO primary_stage FROM relief_requests WHERE id=OLD.primary_request_id FOR UPDATE;
    IF primary_stage <> 'waiting' OR EXISTS (
      SELECT 1 FROM request_history WHERE request_id=OLD.primary_request_id AND action='dispatch.partial'
    ) THEN
      RAISE EXCEPTION 'linked request is being handled' USING ERRCODE='P3101';
    END IF;
    NEW.primary_request_id := NULL;
  END IF;
  RETURN NEW;
END;
$$;
CREATE TRIGGER linked_request_edit BEFORE UPDATE ON relief_requests
FOR EACH ROW EXECUTE FUNCTION check_linked_request_edit();

CREATE FUNCTION notify_dispatch_event() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE notice_text text;
BEGIN
  notice_text := CASE NEW.action
    WHEN 'dispatch.accepted' THEN 'Đội cứu hộ đã tiếp nhận yêu cầu.'
    WHEN 'dispatch.assigned' THEN 'Quản trị đã phân công đội cứu hộ.'
    WHEN 'dispatch.transferred' THEN 'Yêu cầu đã được chuyển sang đội cứu hộ khác.'
    WHEN 'dispatch.returned' THEN 'Đội cứu hộ đã trả nhiệm vụ về chờ tiếp nhận.'
    WHEN 'dispatch.travelling' THEN 'Đội cứu hộ đang di chuyển.'
    WHEN 'dispatch.arrived' THEN 'Đội cứu hộ đã đến nơi.'
    WHEN 'dispatch.partial' THEN 'Yêu cầu đã được hỗ trợ một phần.'
  END;
  IF notice_text IS NOT NULL THEN
    INSERT INTO notices(account_id,request_id,kind,message)
      SELECT owner_id,id,NEW.action,notice_text FROM relief_requests
      WHERE (id=NEW.request_id OR primary_request_id=NEW.request_id) AND stage<>'cancelled';
  END IF;
  IF NEW.action='dispatch.returned' THEN
    INSERT INTO notices(account_id,request_id,kind,message)
      SELECT id,NEW.request_id,NEW.action,'Một đội đã trả nhiệm vụ. Mở yêu cầu để xem lý do.'
      FROM accounts WHERE role='admin' AND locked_at IS NULL AND 'requests:read'=ANY(permissions);
  END IF;
  RETURN NEW;
END;
$$;
CREATE TRIGGER dispatch_notices AFTER INSERT ON request_history
FOR EACH ROW EXECUTE FUNCTION notify_dispatch_event();

CREATE FUNCTION notify_dispatch_completion() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO notices(account_id,request_id,kind,message)
    SELECT owner_id,id,'dispatch.completed','Yêu cầu cứu trợ đã hoàn thành.' FROM relief_requests
    WHERE (id=NEW.id OR primary_request_id=NEW.id) AND stage<>'cancelled';
  RETURN NEW;
END;
$$;
CREATE TRIGGER dispatch_completion_notice AFTER UPDATE OF stage ON relief_requests
FOR EACH ROW WHEN (OLD.stage<>'completed' AND NEW.stage='completed')
EXECUTE FUNCTION notify_dispatch_completion();
