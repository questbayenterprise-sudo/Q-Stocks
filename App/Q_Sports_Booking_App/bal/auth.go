package bal

import (
	"context"
	"fmt"
	"log"
	"math/rand"
	"strconv"
	"strings"
	"time"

	dal "github.com/qsports/q-stocks-app/dal"
	gomail "gopkg.in/gomail.v2"
)

func GenerateOTP() string {
	rand.Seed(time.Now().UnixNano())
	return fmt.Sprintf("%06d", rand.Intn(1000000))
}
func SendOTP(Otp_data Otp_struct) error {
	// 1. Extract and CLEAN credentials from config
	// strings.TrimSpace is CRITICAL to remove hidden newlines/spaces from JSON
	fromEmail := strings.TrimSpace(dal.Cfg.MailAuth.From_MailID)
	appPassword := strings.TrimSpace(dal.Cfg.MailAuth.App_acccode)

	// Debug prints (Check your terminal when running)
	log.Printf("[DEBUG] Attempting to send mail from: %s", fromEmail)
	if fromEmail == "" || appPassword == "" {
		return fmt.Errorf("SMTP credentials are empty. Check if config.json is loaded correctly")
	}

	m := gomail.NewMessage()
	m.SetHeader("From", "Q-Stocks Support <questbayenterprise@gmail.com>")
	m.SetHeader("To", Otp_data.Email)
	m.SetHeader("Subject", "Your OTP Login Code")

	// 2. Define the 'body' variable (Fixes "undefined: body" error)
	body := fmt.Sprintf(`
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: Arial, sans-serif; background-color: #f4f6f8; margin: 0; padding: 0; }
    .container { max-width: 500px; margin: 40px auto; background: #ffffff; padding: 30px; border-radius: 8px; text-align: center; }
    .logo { font-size: 20px; font-weight: bold; color: #2c3e50; margin-bottom: 20px; }
    .otp-box { font-size: 28px; letter-spacing: 6px; font-weight: bold; color: #ffffff; background-color: #4CAF50; padding: 15px 20px; border-radius: 6px; display: inline-block; margin: 20px 0; }
    .footer { margin-top: 30px; font-size: 12px; color: #999; }
  </style>
</head>
<body>
  <div class="container">
    <div class="logo">Q Sports</div>
    <h2>OTP Verification</h2>
    <p>Use the following One-Time Password to continue:</p>
    <div class="otp-box">%s</div>
    <p>This OTP is valid for <b>7 minutes</b>.</p>
    <div class="footer">If you did not request this OTP, please ignore this email.</div>
  </div>
</body>
</html>
`, Otp_data.OTP)

	// 3. Set the body
	m.SetBody("text/html", body)

	// 4. Create the Dialer (Port 587 for Gmail)
	d := gomail.NewDialer(
		"smtp.gmail.com",
		587,
		fromEmail,
		appPassword,
	)

	// 5. Dial and Send
	if err := d.DialAndSend(m); err != nil {
		log.Printf("[SMTP ERROR] Failed to send email: %v", err)
		return err // This will return the "5.7.8" error if the password is still rejected
	}

	log.Printf("[SUCCESS] OTP sent to %s", Otp_data.Email)
	return nil
}
func Verify_OTP_auth(ctx context.Context, Otp_data Otp_struct) string {

	query1 := `
   WITH updated AS (
    UPDATE otp_log
    SET 
        is_verified = TRUE,
        verified_at = CURRENT_TIMESTAMP
    WHERE 
        otp = $1
        AND emailid = $2
        AND is_verified = false
        AND expires_at > CURRENT_TIMESTAMP
    RETURNING 1
)
SELECT EXISTS (SELECT 1 FROM updated) AS success;
`
	var isotp_exists bool
	err := dal.DB.QueryRow(ctx, query1, Otp_data.OTP, Otp_data.Email).Scan(&isotp_exists)
	if err != nil {

		return err.Error()
	} else {
		if isotp_exists {
			return strconv.FormatBool(isotp_exists)
		} else {
			return strconv.FormatBool(isotp_exists)
		}
	}

}

func Simplepass() {
	fmt.Println("vxcvxv")
}
