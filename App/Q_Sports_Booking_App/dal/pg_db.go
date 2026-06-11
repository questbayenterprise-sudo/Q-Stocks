package dal

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type DBCallType int

// DBConfig holds the individual database settings
type DBConfig struct {
	Host     string `json:"host"`
	Port     int    `json:"port"`
	User     string `json:"user"`
	Password string `json:"password"`
	DBName   string `json:"dbname"`
	SSLMode  string `json:"sslmode"`
}

type Mail_Auth struct {
	From_MailID string `json:"from_mailID"`
	App_name    string `json:"appname"`
	App_acccode string `json:"app_acccode"`
}

// Config is the top-level structure
type Config struct {
	Database               DBConfig  `json:"database"`
	MailAuth               Mail_Auth `json:"mailauth"`
	FcmServerKey           string    `json:"fcm_server_key"`
	FcmServiceAccountPath  string    `json:"fcm_service_account_path"`
	FcmProjectID           string    `json:"fcm_project_id"`
}

const (
	Function DBCallType = iota
	Procedure
)

var DB *pgxpool.Pool
var Cfg Config

// config/config.go (continued)

func LoadConfig(filePath string) (*Config, error) {
	data, err := os.ReadFile(filePath)
	if err != nil {
		return nil, fmt.Errorf("failed to read config file: %w", err)
	}

	//var Cfg Config
	if err := json.Unmarshal(data, &Cfg); err != nil {
		return nil, fmt.Errorf("failed to parse config json: %w", err)
	}

	return &Cfg, nil
}

// DSN builds the PostgreSQL connection string from the config fields
func (c *Config) DSN() string {
	// Format: postgres://user:password@host:port/dbname?sslmode=...
	return fmt.Sprintf(
		"postgres://%s:%s@%s:%d/%s?sslmode=%s",
		c.Database.User,
		c.Database.Password,
		c.Database.Host,
		c.Database.Port,
		c.Database.DBName,
		c.Database.SSLMode,
	)
}

func ConnectPostgres() error {
	var err error
	Cfg, err := LoadConfig("config.json")
	if err != nil {
		return fmt.Errorf("failed to load config: %w", err)
	}

	// Build the connection string
	connString := Cfg.DSN()
	DB, err = pgxpool.New(context.Background(), connString)
	if err != nil {
		return fmt.Errorf("unable to create connection pool: %w", err)
	}

	err = DB.Ping(context.Background())

	err = DB.Ping(context.Background())
	if err != nil {
		return fmt.Errorf("unable to ping database: %w", err)
	}
	return nil
}

func checkInit() error {
	if DB == nil {
		if err := ConnectPostgres(); err != nil {
			return errors.New("database connection not initialized. ensure ConnectPostgres is called in main.go")
		}
	}
	return nil
}

func Query(ctx context.Context, query string, args ...any) (pgx.Rows, error) {
	if err := checkInit(); err != nil {
		return nil, err
	}
	return DB.Query(ctx, query, args...)
}

func ExecSelectJSON(ctx context.Context, query string, args ...any) ([]byte, error) {
	if err := checkInit(); err != nil {
		return nil, err
	}
	var result []byte
	err := DB.QueryRow(ctx, query, args...).Scan(&result)
	return result, err
}

func ExecNonQuery(ctx context.Context, query string, args ...any) (int64, error) {
	if err := checkInit(); err != nil {
		return 0, err
	}
	cmd, err := DB.Exec(ctx, query, args...)
	if err != nil {
		return 0, err
	}
	return cmd.RowsAffected(), nil
}

// Added this to support the Scan logic in bal
func QueryRow(ctx context.Context, query string, args ...any) pgx.Row {
	return DB.QueryRow(ctx, query, args...)
}

func Insert_venue_booking(ctx context.Context, CusUserId string, CourtId string, VenueId string, SlotId string, insertQueryBlock string, updateQueryBlock string) string {

	// ────────────────────────────────────────────────

	// Start transaction here

	// ────────────────────────────────────────────────

	tx, err := DB.Begin(ctx)

	if err != nil {

		return "Error while making DB connection"

	}

	// Important: if anything goes wrong later → rollback automatically

	defer tx.Rollback(ctx) // ← this line is magic

	// 1. Insert booking

	_, err = tx.Exec(ctx, insertQueryBlock, CusUserId, CourtId, VenueId, SlotId)

	if err != nil {

		return "Error while inserting the booking details" // ← defer rollback will run automatically

	}

	// 2. Update slot status

	_, err = tx.Exec(ctx, updateQueryBlock, VenueId, CourtId, SlotId)

	if err != nil {

		return "Error while marking bookings is completed in the slottime table" // ← rollback happens

	}

	// Everything OK → commit (make changes permanent)

	if err := tx.Commit(ctx); err != nil {

		return "Error while committing the insert and update of venue booking details"

	}

	// Success

	return "success"

}

// Add this to lib/dal/dal.go
func Exec(ctx context.Context, query string, args ...any) (int64, error) {
	if err := checkInit(); err != nil {
		return 0, err
	}
	cmd, err := DB.Exec(ctx, query, args...)
	if err != nil {
		return 0, err
	}
	return cmd.RowsAffected(), nil
}
