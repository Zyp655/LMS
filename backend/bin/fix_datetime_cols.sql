-- Fix all timestamp columns to bigint for Drift compatibility

ALTER TABLE ai_notification_logs ALTER COLUMN date TYPE bigint USING CASE WHEN date IS NOT NULL THEN EXTRACT(EPOCH FROM date)::bigint ELSE NULL END;
ALTER TABLE ai_notification_logs ALTER COLUMN sent_at TYPE bigint USING CASE WHEN sent_at IS NOT NULL THEN EXTRACT(EPOCH FROM sent_at)::bigint ELSE NULL END;

ALTER TABLE daily_learning_logs ALTER COLUMN date TYPE bigint USING CASE WHEN date IS NOT NULL THEN EXTRACT(EPOCH FROM date)::bigint ELSE NULL END;
ALTER TABLE daily_learning_logs ALTER COLUMN first_access_at TYPE bigint USING CASE WHEN first_access_at IS NOT NULL THEN EXTRACT(EPOCH FROM first_access_at)::bigint ELSE NULL END;
ALTER TABLE daily_learning_logs ALTER COLUMN last_access_at TYPE bigint USING CASE WHEN last_access_at IS NOT NULL THEN EXTRACT(EPOCH FROM last_access_at)::bigint ELSE NULL END;
ALTER TABLE daily_learning_logs ALTER COLUMN finalized_at TYPE bigint USING CASE WHEN finalized_at IS NOT NULL THEN EXTRACT(EPOCH FROM finalized_at)::bigint ELSE NULL END;

ALTER TABLE segment_quiz_attempts ALTER COLUMN last_attempt_at TYPE bigint USING CASE WHEN last_attempt_at IS NOT NULL THEN EXTRACT(EPOCH FROM last_attempt_at)::bigint ELSE NULL END;

ALTER TABLE video_segments ALTER COLUMN created_at TYPE bigint USING CASE WHEN created_at IS NOT NULL THEN EXTRACT(EPOCH FROM created_at)::bigint ELSE NULL END;
