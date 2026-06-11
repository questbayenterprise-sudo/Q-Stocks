package bal

import (
	"context"
	"fmt"
	"math/rand"
	"strconv"
	"time"

	dal "github.com/qsports/q-sports-booking-app/dal"
	gomail "gopkg.in/gomail.v2"
)

func GenerateOTP() string {
	rand.Seed(time.Now().UnixNano())
	return fmt.Sprintf("%06d", rand.Intn(1000000))
}

func SendOTP(Otp_data Otp_struct) error {

	m := gomail.NewMessage()
	m.SetHeader("From", dal.Cfg.MailAuth.From_MailID)
	m.SetHeader("To", Otp_data.Email)
	m.SetHeader("Subject", "Your OTP Login Code")

	body := fmt.Sprintf(`
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body {
      font-family: Arial, sans-serif;
      background-color: #f4f6f8;
      margin: 0;
      padding: 0;
    }
    .container {
      max-width: 500px;
      margin: 40px auto;
      background: #ffffff;
      padding: 30px;
      border-radius: 8px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.08);
      text-align: center;
    }
    .logo {
      font-size: 20px;
      font-weight: bold;
      color: #2c3e50;
      margin-bottom: 20px;
    }
    .otp-box {
      font-size: 28px;
      letter-spacing: 6px;
      font-weight: bold;
      color: #ffffff;
      background-color: #4CAF50;
      padding: 15px 20px;
      border-radius: 6px;
      display: inline-block;
      margin: 20px 0;
    }
    .text {
      color: #555;
      font-size: 14px;
    }
    .footer {
      margin-top: 30px;
      font-size: 12px;
      color: #999;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="logo">Q Sports</div>
    <h2>OTP Verification</h2>
    <p class="text">Use the following One-Time Password to continue:</p>
    <div class="otp-box">%s</div>
    <p class="text">This OTP is valid for <b>7 minutes</b>.</p>
    <div class="footer">
      If you did not request this OTP, please ignore this email.
    </div>
  </div>
</body>
</html>
`, Otp_data.OTP)

	m.SetBody("text/html", body)

	d := gomail.NewDialer(
		"smtp.gmail.com",
		587,
		dal.Cfg.MailAuth.From_MailID,
		dal.Cfg.MailAuth.App_acccode,
	)

	return d.DialAndSend(m)
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
