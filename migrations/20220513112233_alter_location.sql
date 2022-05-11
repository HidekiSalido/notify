-- +goose Up
ALTER TABLE location ADD COLUMN IF NOT EXISTS auto_eod_time TIMESTAMP WITH TIME ZONE;

-- +goose Down
ALTER TABLE location DROP COLUMN IF EXISTS auto_eod_time;