ALTER TABLE evidence ADD COLUMN thumbnail_sha256 text CHECK(thumbnail_sha256 IS NULL OR thumbnail_sha256 ~ '^[0-9a-f]{64}$');
