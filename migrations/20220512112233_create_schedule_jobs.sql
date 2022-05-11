-- +goose Up
CREATE TABLE IF NOT EXISTS schedule_jobs
(
    id                  BIGSERIAL PRIMARY KEY
    ,location_id        BIGINT NOT NULL REFERENCES location(id) ON DELETE CASCADE
    ,check_id           BIGINT REFERENCES cheque(id) ON DELETE CASCADE
    ,job_type           TEXT NOT NULL
    ,job_conf           jsonb NOT NULL
    ,scheduled_at       TIMESTAMP WITH TIME ZONE
    ,state              TEXT
    ,failures           jsonb NULL
    ,failed_count       INT NOT NULL DEFAULT 0
);
COMMENT ON TABLE schedule_jobs IS '
    job_conf stores {recurring, cron, maxRetryCount, timeoutSec, retryDelaySec}

    failures stores [{err(error message), scheduled_at, failed_at}]
';

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION after_schedule_jobs_modify()
RETURNS TRIGGER as $$
DECLARE
    rec RECORD;
    payload TEXT;
    notify INT DEFAULT 0;
BEGIN
    CASE TG_OP
    WHEN 'INSERT' THEN
        rec := NEW;
        notify := 1;
    WHEN 'DELETE' THEN
        rec := OLD;
        notify := 1;
    WHEN 'UPDATE' THEN
        rec := NEW;
        -- only notify for job_conf change
        IF(NEW.job_conf <> OLD.job_conf) THEN
            notify := 1;
        END IF;
    END CASE;
    IF notify = 1 THEN
        payload := json_build_object('op', TG_OP, 'scheduleJob', row_to_json(rec));
        PERFORM pg_notify('schedule_jobs_notify', payload);
    END IF;
    return rec;
END;
$$
LANGUAGE plpgsql;
-- +goose StatementEnd
COMMENT ON FUNCTION after_schedule_jobs_modify IS '
    after_schedule_jobs_modify performs notify to schedule_jobs_notify channel when record is added or updated or deleted.
';

CREATE TRIGGER trigger_after_schedule_jobs_modify
   AFTER INSERT OR UPDATE OR DELETE ON schedule_jobs FOR EACH ROW
   EXECUTE PROCEDURE after_schedule_jobs_modify();

-- +goose Down
-- +goose StatementBegin
DROP TRIGGER IF EXISTS trigger_after_schedule_jobs_modify ON schedule_jobs;
DROP FUNCTION IF EXISTS after_schedule_jobs_modify;
-- +goose StatementEnd

DROP TABLE IF EXISTS schedule_jobs;
