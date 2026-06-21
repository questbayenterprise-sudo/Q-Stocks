package bal

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"golang.org/x/oauth2/google"

	dal "github.com/qsports/q-stocks-app/dal"
	gomail "gopkg.in/gomail.v2"
)

// --- Save FCM Token endpoint (upsert per device) ---
type SaveFcmTokenRequest struct {
	UserID   string `json:"user_id" binding:"required"`
	FcmToken string `json:"fcm_token" binding:"required"`
	DeviceID string `json:"device_id"`
	Platform string `json:"platform"`
}

func Save_FcmToken(c *gin.Context) {
	var req SaveFcmTokenRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid Request"})
		return
	}

	platform := req.Platform
	if platform == "" {
		platform = "android"
	}

	// Upsert: if same user+token exists, update timestamp; otherwise insert
	query := `
		INSERT INTO user_fcm_tokens (user_id, fcm_token, device_id, platform, is_active, updated_at)
		VALUES ($1, $2, $3, $4, true, CURRENT_TIMESTAMP)
		ON CONFLICT (user_id, fcm_token)
		DO UPDATE SET device_id = $3, platform = $4, is_active = true, updated_at = CURRENT_TIMESTAMP
	`
	_, err := dal.ExecNonQuery(c.Request.Context(), query, req.UserID, req.FcmToken, req.DeviceID, platform)
	if err != nil {
		log.Printf("[FCM] Error saving token for user %s: %v", req.UserID, err)
		c.JSON(http.StatusOK, gin.H{"success": false, "message": "Database error"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"success": true, "message": "FCM token saved"})
}

// --- Remove FCM Token endpoint (on logout) ---
type RemoveFcmTokenRequest struct {
	UserID   string `json:"user_id" binding:"required"`
	FcmToken string `json:"fcm_token" binding:"required"`
}

func Remove_FcmToken(c *gin.Context) {
	var req RemoveFcmTokenRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid Request"})
		return
	}

	query := `UPDATE user_fcm_tokens SET is_active = false, updated_at = CURRENT_TIMESTAMP
			  WHERE user_id = $1 AND fcm_token = $2`
	_, _ = dal.ExecNonQuery(c.Request.Context(), query, req.UserID, req.FcmToken)

	c.JSON(http.StatusOK, gin.H{"success": true, "message": "FCM token removed"})
}

// --- Test notification endpoint (for debugging) ---
func Test_Notification(c *gin.Context) {
	var req struct {
		UserID string `json:"user_id" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid Request"})
		return
	}

	// Test with dummy booking data
	TriggerBookingNotifications(BookingNotifyData{
		BookingID:  9999,
		BookingRef: "QS-TEST-0001",
		UserID:     req.UserID,
		VenueName:  "Test Venue",
		SportName:  "Cricket",
		Date:       "2026-03-22",
		StartTime:  "10:00 AM",
		EndTime:    "11:00 AM",
		Amount:     "1200",
	})

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Notification triggered — check server logs for results",
	})
}

// --- Debug notification endpoint (synchronous — returns all details) ---
func Debug_Notification(c *gin.Context) {
	var req struct {
		UserID string `json:"user_id" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid Request"})
		return
	}

	ctx := c.Request.Context()
	debugLog := []string{}

	// 1. Check config
	debugLog = append(debugLog, fmt.Sprintf("FCM project_id: %s", dal.Cfg.FcmProjectID))
	debugLog = append(debugLog, fmt.Sprintf("FCM service_account_path: %s", dal.Cfg.FcmServiceAccountPath))

	if _, err := os.Stat(dal.Cfg.FcmServiceAccountPath); os.IsNotExist(err) {
		debugLog = append(debugLog, "ERROR: firebase-service-account.json NOT FOUND")
		c.JSON(http.StatusOK, gin.H{"success": false, "debug": debugLog})
		return
	}
	debugLog = append(debugLog, "OK: service account file exists")

	// 2. Test OAuth token
	accessToken, err := getFCMAccessToken()
	if err != nil {
		debugLog = append(debugLog, fmt.Sprintf("ERROR getting OAuth token: %v", err))
		c.JSON(http.StatusOK, gin.H{"success": false, "debug": debugLog})
		return
	}
	debugLog = append(debugLog, fmt.Sprintf("OK: OAuth token obtained (length: %d)", len(accessToken)))

	// 3. Check user exists
	user, err := fetchUserNotifyInfo(ctx, req.UserID)
	if err != nil {
		debugLog = append(debugLog, fmt.Sprintf("ERROR fetching user info: %v", err))
		c.JSON(http.StatusOK, gin.H{"success": false, "debug": debugLog})
		return
	}
	debugLog = append(debugLog, fmt.Sprintf("OK: User found — %s (%s), push=%v, email=%v", user.Username, user.Email, user.PushEnabled, user.EmailEnabled))

	// 4. Check FCM tokens
	tokens, err := fetchUserFcmTokens(ctx, req.UserID)
	if err != nil {
		debugLog = append(debugLog, fmt.Sprintf("ERROR fetching FCM tokens: %v", err))
		c.JSON(http.StatusOK, gin.H{"success": false, "debug": debugLog})
		return
	}
	debugLog = append(debugLog, fmt.Sprintf("Found %d FCM token(s)", len(tokens)))

	if len(tokens) == 0 {
		debugLog = append(debugLog, "ERROR: No FCM tokens found for this user — app has not saved the token")
		c.JSON(http.StatusOK, gin.H{"success": false, "debug": debugLog})
		return
	}

	// 5. Try sending to each token
	testData := BookingNotifyData{
		BookingID:  9999,
		BookingRef: "QS-DEBUG-0001",
		UserID:     req.UserID,
		VenueName:  "Debug Test Venue",
		Date:       "2026-03-29",
		StartTime:  "10:00 AM",
		EndTime:    "11:00 AM",
	}

	pushResults := []gin.H{}
	for i, token := range tokens {
		tokenPreview := token
		if len(token) > 30 {
			tokenPreview = token[:30] + "..."
		}

		err := sendFCMNotification(token, testData)
		if err != nil {
			debugLog = append(debugLog, fmt.Sprintf("FAILED token[%d] (%s): %v", i, tokenPreview, err))
			pushResults = append(pushResults, gin.H{"token": tokenPreview, "status": "failed", "error": err.Error()})
		} else {
			debugLog = append(debugLog, fmt.Sprintf("OK token[%d] (%s): push sent", i, tokenPreview))
			pushResults = append(pushResults, gin.H{"token": tokenPreview, "status": "sent"})
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"success":      true,
		"debug":        debugLog,
		"push_results": pushResults,
		"user":         gin.H{"username": user.Username, "email": user.Email, "push_enabled": user.PushEnabled},
		"token_count":  len(tokens),
	})
}

// --- Booking notification data ---
type BookingNotifyData struct {
	BookingID  int
	BookingRef string
	UserID     string
	VenueName  string
	SportName  string
	Date       string
	StartTime  string
	EndTime    string
	Amount     string
}

// --- User notification info fetched from DB ---
type UserNotifyInfo struct {
	Username     string
	Email        string
	PushEnabled  bool
	EmailEnabled bool
}

// --- Trigger notifications asynchronously (non-blocking) ---
func TriggerBookingNotifications(data BookingNotifyData) {
	go func() {
		ctx := context.Background()
		now := time.Now().Format("2006-01-02 15:04:05")

		// 1. Fetch user notification info
		user, err := fetchUserNotifyInfo(ctx, data.UserID)
		if err != nil {
			log.Printf("[NOTIFY] %s Error fetching user info for user %s: %v", now, data.UserID, err)
			return
		}

		// 2. Send push notification to ALL active devices
		if user.PushEnabled {
			tokens, err := fetchUserFcmTokens(ctx, data.UserID)
			if err != nil {
				log.Printf("[NOTIFY] %s Error fetching FCM tokens for user %s: %v", now, data.UserID, err)
			} else if len(tokens) == 0 {
				log.Printf("[NOTIFY] %s No active FCM tokens for user %s, skipping push", now, data.UserID)
			} else {
				for _, token := range tokens {
					if err := sendFCMNotification(token, data); err != nil {
						log.Printf("[NOTIFY] %s FCM push failed for user %s (token: %s...): %v", now, data.UserID, token[:min(len(token), 20)], err)
					} else {
						log.Printf("[NOTIFY] %s FCM push sent to user %s (token: %s...)", now, data.UserID, token[:min(len(token), 20)])
					}
				}
			}
		} else {
			log.Printf("[NOTIFY] %s Push disabled for user %s, skipping", now, data.UserID)
		}

		// 3. Send email notification (if email exists and enabled)
		if user.Email != "" && user.EmailEnabled {
			if err := sendBookingConfirmationEmail(user, data); err != nil {
				log.Printf("[NOTIFY] %s Email failed for user %s (%s): %v", now, data.UserID, user.Email, err)
			} else {
				log.Printf("[NOTIFY] %s Email sent to %s", now, user.Email)
			}
		} else {
			log.Printf("[NOTIFY] %s Skipping email for user %s (email=%v, enabled=%v)", now, data.UserID, user.Email != "", user.EmailEnabled)
		}
	}()
}

// --- Fetch user notification preferences ---
func fetchUserNotifyInfo(ctx context.Context, userID string) (*UserNotifyInfo, error) {
	query := `
		SELECT
			u.username,
			COALESCE(u.email, '') as email,
			COALESCE(us.push_notify, true) as push_notify,
			COALESCE(us.mail_upd, true) as mail_upd
		FROM users u
		LEFT JOIN user_settings us ON us.user_id = u.id AND us.isdelete = 0
		WHERE u.id = $1 AND u.is_active = true
	`

	var info UserNotifyInfo
	err := dal.DB.QueryRow(ctx, query, userID).Scan(
		&info.Username,
		&info.Email,
		&info.PushEnabled,
		&info.EmailEnabled,
	)
	if err != nil {
		return nil, err
	}
	return &info, nil
}

// --- Fetch all active FCM tokens for a user (all devices) ---
func fetchUserFcmTokens(ctx context.Context, userID string) ([]string, error) {
	query := `SELECT fcm_token FROM user_fcm_tokens WHERE user_id = $1 AND is_active = true`

	rows, err := dal.DB.Query(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var tokens []string
	for rows.Next() {
		var token string
		if err := rows.Scan(&token); err != nil {
			continue
		}
		tokens = append(tokens, token)
	}
	return tokens, nil
}

// --- Get OAuth2 access token from service account ---
func getFCMAccessToken() (string, error) {
	jsonKey, err := os.ReadFile(dal.Cfg.FcmServiceAccountPath)
	if err != nil {
		return "", fmt.Errorf("failed to read service account file: %w", err)
	}

	conf, err := google.JWTConfigFromJSON(jsonKey, "https://www.googleapis.com/auth/firebase.messaging")
	if err != nil {
		return "", fmt.Errorf("failed to parse service account: %w", err)
	}

	token, err := conf.TokenSource(context.Background()).Token()
	if err != nil {
		return "", fmt.Errorf("failed to get access token: %w", err)
	}

	return token.AccessToken, nil
}

// --- Send FCM push notification via v1 API ---
func sendFCMNotification(fcmToken string, data BookingNotifyData) error {
	accessToken, err := getFCMAccessToken()
	if err != nil {
		return fmt.Errorf("auth error: %w", err)
	}

	projectID := dal.Cfg.FcmProjectID
	url := fmt.Sprintf("https://fcm.googleapis.com/v1/projects/%s/messages:send", projectID)

	payload := map[string]interface{}{
		"message": map[string]interface{}{
			"token": fcmToken,
			"notification": map[string]string{
				"title": "Booking Confirmed!",
				"body":  fmt.Sprintf("Your booking at %s on %s is confirmed.", data.VenueName, data.Date),
			},
			"data": map[string]string{
				"bookingId": fmt.Sprintf("%d", data.BookingID),
				"type":      "BOOKING_CONFIRMED",
			},
		},
	}

	body, err := json.Marshal(payload)
	if err != nil {
		return err
	}

	req, err := http.NewRequest("POST", url, bytes.NewBuffer(body))
	if err != nil {
		return err
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+accessToken)

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		var respBody map[string]interface{}
		json.NewDecoder(resp.Body).Decode(&respBody)
		return fmt.Errorf("FCM v1 returned status %d: %v", resp.StatusCode, respBody)
	}

	return nil
}

// --- Send booking confirmation email ---
func sendBookingConfirmationEmail(user *UserNotifyInfo, data BookingNotifyData) error {
	m := gomail.NewMessage()
	m.SetHeader("From", dal.Cfg.MailAuth.From_MailID)
	m.SetHeader("To", user.Email)
	m.SetHeader("Subject", fmt.Sprintf("Booking %s - %s", data.BookingRef, data.VenueName))

	// Sport row (only show if sport selected)
	sportRow := ""
	if data.SportName != "" {
		sportRow = fmt.Sprintf(`
          <tr>
            <td style="padding:14px 20px;color:#6b7280;font-size:13px;border-bottom:1px solid #f3f4f6;">Sport</td>
            <td style="padding:14px 20px;color:#1f2937;font-size:14px;font-weight:600;text-align:right;border-bottom:1px solid #f3f4f6;">%s</td>
          </tr>`, data.SportName)
	}

	// Amount row (only show if amount > 0)
	amountRow := ""
	if data.Amount != "" && data.Amount != "0" {
		amountRow = fmt.Sprintf(`
          <tr>
            <td style="padding:14px 20px;color:#6b7280;font-size:13px;">Amount</td>
            <td style="padding:14px 20px;text-align:right;">
              <span style="background:#00A36C;color:white;padding:4px 14px;border-radius:20px;font-size:14px;font-weight:700;">&#8377;%s</span>
            </td>
          </tr>`, data.Amount)
	}

	body := fmt.Sprintf(`
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="font-family:'Segoe UI',Arial,sans-serif;background-color:#f0f2f5;margin:0;padding:0;">
  <table width="100%%" cellpadding="0" cellspacing="0" style="background:#f0f2f5;padding:30px 0;">
    <tr><td align="center">
      <table width="520" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:20px;overflow:hidden;box-shadow:0 8px 30px rgba(0,0,0,0.06);">

        <!-- Header -->
        <tr>
          <td style="background:linear-gradient(135deg,#00A36C,#00C781);padding:36px 24px;text-align:center;">
            <div style="width:64px;height:64px;background:rgba(255,255,255,0.2);border-radius:50%%;margin:0 auto 12px;line-height:64px;font-size:32px;">&#9989;</div>
            <h1 style="color:#ffffff;margin:0;font-size:24px;letter-spacing:0.5px;">Booking Confirmed!</h1>
            <p style="color:rgba(255,255,255,0.85);margin:10px 0 0;font-size:14px;">Your turf is reserved and ready to play</p>
          </td>
        </tr>

        <!-- Booking Ref Banner -->
        <tr>
          <td style="padding:20px 24px 0;text-align:center;">
            <table cellpadding="0" cellspacing="0" style="background:#f0fdf4;border:2px dashed #86efac;border-radius:12px;width:100%%;">
              <tr>
                <td style="padding:16px;text-align:center;">
                  <span style="color:#6b7280;font-size:12px;text-transform:uppercase;letter-spacing:1px;">Booking Reference</span><br/>
                  <span style="color:#00A36C;font-size:22px;font-weight:800;letter-spacing:1px;">%s</span>
                </td>
              </tr>
            </table>
          </td>
        </tr>

        <!-- Greeting -->
        <tr>
          <td style="padding:24px 24px 8px;">
            <p style="font-size:17px;font-weight:600;color:#1f2937;margin:0;">Hi %s,</p>
            <p style="color:#6b7280;font-size:14px;line-height:1.6;margin:8px 0 0;">
              Your booking has been confirmed. Here are the details:
            </p>
          </td>
        </tr>

        <!-- Details Table -->
        <tr>
          <td style="padding:8px 24px 20px;">
            <table width="100%%" cellpadding="0" cellspacing="0" style="background:#fafbfc;border:1px solid #e5e7eb;border-radius:14px;overflow:hidden;">
              <tr>
                <td style="padding:14px 20px;color:#6b7280;font-size:13px;border-bottom:1px solid #f3f4f6;">Venue</td>
                <td style="padding:14px 20px;color:#1f2937;font-size:14px;font-weight:600;text-align:right;border-bottom:1px solid #f3f4f6;">%s</td>
              </tr>
              %s
              <tr>
                <td style="padding:14px 20px;color:#6b7280;font-size:13px;border-bottom:1px solid #f3f4f6;">Date</td>
                <td style="padding:14px 20px;color:#1f2937;font-size:14px;font-weight:600;text-align:right;border-bottom:1px solid #f3f4f6;">%s</td>
              </tr>
              <tr>
                <td style="padding:14px 20px;color:#6b7280;font-size:13px;border-bottom:1px solid #f3f4f6;">Time</td>
                <td style="padding:14px 20px;color:#1f2937;font-size:14px;font-weight:600;text-align:right;border-bottom:1px solid #f3f4f6;">%s &mdash; %s</td>
              </tr>
              <tr>
                <td style="padding:14px 20px;color:#6b7280;font-size:13px;border-bottom:1px solid #f3f4f6;">Status</td>
                <td style="padding:14px 20px;text-align:right;border-bottom:1px solid #f3f4f6;">
                  <span style="background:#dcfce7;color:#166534;padding:5px 14px;border-radius:20px;font-size:12px;font-weight:700;letter-spacing:0.5px;">CONFIRMED</span>
                </td>
              </tr>
              %s
            </table>
          </td>
        </tr>

        <!-- Reminder -->
        <tr>
          <td style="padding:0 24px 24px;">
            <table width="100%%" cellpadding="0" cellspacing="0" style="background:#fffbeb;border:1px solid #fde68a;border-radius:12px;">
              <tr>
                <td style="padding:14px 18px;">
                  <p style="margin:0;color:#92400e;font-size:13px;line-height:1.6;">
                    <strong>&#128161; Reminder:</strong> Arrive 10 minutes early. Show your booking reference or QR code at the venue for quick check-in.
                  </p>
                </td>
              </tr>
            </table>
          </td>
        </tr>

        <!-- Footer -->
        <tr>
          <td style="text-align:center;padding:20px 24px;border-top:1px solid #f3f4f6;background:#fafbfc;">
            <p style="margin:0;color:#00A36C;font-weight:800;font-size:16px;letter-spacing:0.5px;">Q-Sports</p>
            <p style="margin:6px 0 0;color:#9ca3af;font-size:12px;">Book. Play. Repeat.</p>
            <p style="margin:4px 0 0;color:#d1d5db;font-size:11px;">This is an automated email. Please do not reply.</p>
          </td>
        </tr>

      </table>
    </td></tr>
  </table>
</body>
</html>
`, data.BookingRef, user.Username, data.VenueName, sportRow, data.Date, data.StartTime, data.EndTime, amountRow)

	m.SetBody("text/html", body)

	d := gomail.NewDialer(
		"smtp.gmail.com",
		587,
		dal.Cfg.MailAuth.From_MailID,
		dal.Cfg.MailAuth.App_acccode,
	)

	return d.DialAndSend(m)
}

// ════════════════════════════════════════════════════
// NOTIFICATIONS TABLE ENDPOINTS
// ════════════════════════════════════════════════════

// --- Get user notifications ---
func GetNotifications(c *gin.Context) {
	var req struct {
		UserID string `json:"user_id" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid Request"})
		return
	}

	query := `
		SELECT id, type, title, COALESCE(body, ''), data, is_read,
		       TO_CHAR(created_at, 'YYYY-MM-DD HH24:MI') as created_at
		FROM notifications
		WHERE user_id = $1
		ORDER BY created_at DESC
		LIMIT 50
	`
	rows, err := dal.Query(c.Request.Context(), query, req.UserID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Database error"})
		return
	}
	defer rows.Close()

	var notifications []gin.H
	for rows.Next() {
		var id int
		var nType, title, body, createdAt string
		var data []byte
		var isRead bool
		if err := rows.Scan(&id, &nType, &title, &body, &data, &isRead, &createdAt); err != nil {
			continue
		}
		var dataMap map[string]interface{}
		json.Unmarshal(data, &dataMap)

		notifications = append(notifications, gin.H{
			"id":         id,
			"type":       nType,
			"title":      title,
			"body":       body,
			"data":       dataMap,
			"is_read":    isRead,
			"created_at": createdAt,
		})
	}

	// Get unread count
	var unreadCount int
	dal.DB.QueryRow(c.Request.Context(),
		"SELECT COUNT(*) FROM notifications WHERE user_id=$1 AND is_read=false", req.UserID).Scan(&unreadCount)

	c.JSON(http.StatusOK, gin.H{
		"success":      true,
		"data":         notifications,
		"unread_count": unreadCount,
	})
}

// --- Mark notification as read ---
func MarkNotificationRead(c *gin.Context) {
	var req struct {
		ID     int    `json:"id"`
		UserID string `json:"user_id"`
		All    bool   `json:"all"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid Request"})
		return
	}

	ctx := c.Request.Context()
	if req.All && req.UserID != "" {
		dal.ExecNonQuery(ctx, "UPDATE notifications SET is_read=true WHERE user_id=$1 AND is_read=false", req.UserID)
	} else if req.ID > 0 {
		dal.ExecNonQuery(ctx, "UPDATE notifications SET is_read=true WHERE id=$1", req.ID)
	}

	c.JSON(http.StatusOK, gin.H{"success": true, "message": "Marked as read"})
}

// --- Get unread notification count ---
func GetUnreadNotificationCount(c *gin.Context) {
	var req struct {
		UserID string `json:"user_id" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid Request"})
		return
	}

	var count int
	dal.DB.QueryRow(c.Request.Context(),
		"SELECT COUNT(*) FROM notifications WHERE user_id=$1 AND is_read=false", req.UserID).Scan(&count)

	c.JSON(http.StatusOK, gin.H{"success": true, "count": count})
}

// --- Insert notification (internal helper, called from booking flow) ---
func InsertNotification(ctx context.Context, userID string, nType string, title string, body string, data map[string]interface{}) {
	dataJSON, _ := json.Marshal(data)
	_, err := dal.ExecNonQuery(ctx,
		`INSERT INTO notifications (user_id, type, title, body, data) VALUES ($1, $2, $3, $4, $5)`,
		userID, nType, title, body, dataJSON)
	if err != nil {
		log.Printf("[NOTIFY] Failed to insert notification for user %s: %v", userID, err)
	}
}
