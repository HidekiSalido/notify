package main

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgxlisten"

	"github.com/robfig/cron/v3"
)

const (
	connection = "postgres://postgres:postgres@localhost:5438/postgres?connect_timeout=180&sslmode=disable"
)

type ScheduleJob struct {
	ID          int64  `json:"id"`
	LocationID  int64  `json:"location_id"`
	JobType     string `json:"job_type"`
	JobID       string `json:"job_id"`
	ScheduledAt string `json:"scheduled_at"`
	State       string `json:"state"`
	Failures    string `json:"failures"`
	FailedCount int    `json:"failed_count"`
	Args        string `json:"args"`
}

func StartNotifyListen() {
	notifyListener := &pgxlisten.Listener{
		Connect: func(ctx context.Context) (*pgx.Conn, error) {
			config, err := pgx.ParseConfig(connection)
			if err != nil {
				panic(err)
			}
			return pgx.ConnectConfig(ctx, config)
		},
	}
	notifyChan := make(chan *pgconn.Notification)

	notifyListener.Handle("schedule_jobs_notify", pgxlisten.HandlerFunc(func(ctx context.Context, notification *pgconn.Notification, conn *pgx.Conn) error {
		select {
		case notifyChan <- notification:
		case <-ctx.Done():
		}
		return nil
	}))

	go func() {
		notifyListener.Listen(context.Background())
	}()

	type payload struct {
		OP          string      `json:"op"`
		ScheduleJob ScheduleJob `json:"schedule"`
	}

	for {
		msg := <-notifyChan
		payload := payload{}
		json.Unmarshal([]byte(string(msg.Payload)), &payload)
		fmt.Println("msg", msg)
		fmt.Println("payload", payload)
	}
}

func TestCron() {
	c := cron.New(cron.WithLocation(time.UTC))

	entry, err := c.AddFunc("@every 1s", func() { fmt.Println("1") })
	if err != nil {
		panic(err)
	}
	c.Remove(entry)

	// recurrsive
	_, err = c.AddFunc("CRON_TZ=America/Chicago 0 2 * * *", func() { fmt.Println("2") })
	if err != nil {
		panic(err)
	}

	// oneshot test
	_, err = c.AddFunc("CRON_TZ=America/Chicago 15 8 6 9 *", func() { fmt.Println("3") })
	if err != nil {
		panic(err)
	}
	c.Start()

	for _, entry := range c.Entries() {
		fmt.Printf("%+v\n", entry)
	}
}

func main() {
	TestCron()
	StartNotifyListen()
}
