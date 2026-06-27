package bal

import (
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	dal "github.com/qsports/q-stocks-app/dal"
)

// --- Internal Helpers ---

type User struct {
	ID       int    `json:"id"`
	Username string `json:"name"`
	Email    string `json:"email"`
	Phoneno  string `json:"phoneno"`
	Acccode  string `json:"acccode"`
	Usertype string `json:"userType"`
}

type VerifyEmailResponse struct {
	Exists  int    `json:"exists"`
	Message string `json:"message"`
}

// var store = sessions.NewCookieStore([]byte("secret-key"))

// var loginTmpl = template.Must(template.ParseFiles("login.html"))

func VerifyEmail(c *gin.Context) {

	email := c.PostForm("email")
	if email == "" {

	}

	// Simulated DB check
	emailExists := false //db call// true / false

	//var response VerifyEmailResponse
	if !emailExists {
		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"status":  http.StatusOK,
			"message": "MailID doesnt exists",
			"data":    nil,
		})

	} else {
		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"status":  http.StatusOK,
			"message": "MailID exists",
			"data":    nil,
		})
	}
	// w.Header().Set("Content-Type", "application/json")
	// json.NewEncoder(w).Encode(response)
}

type UserProfileRequest struct {
	UserID string `json:"user_id"`
}

type UserProfileResponse struct {
	ID       int    `json:"id"`
	Username string `json:"username"`
	Email    string `json:"email"`
	PhoneNo  string `json:"phoneno"`
	AccCode  string `json:"acccode"`
	Bio      string `json:"bio"`
	ImageURL string `json:"image_url"`
	City     string `json:"city"`
}

func Get_UserProfile(c *gin.Context) {
	var req UserProfileRequest
	ctx := c.Request.Context()

	// 1. Bind the incoming JSON request
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid Request"})
		return
	}

	// 2. SQL Query to get user details
	// We use COALESCE for bio and image_url in case they are NULL in the database
	query := `
		SELECT
			id,
			username,
			email,
			phoneno,
			acccode,
			COALESCE(bio, '') as bio,
			COALESCE(image_url, '') as image_url,
			COALESCE(city, '') as city
		FROM users
		WHERE id = $1
	`

	var up UserProfileResponse
	err := dal.DB.QueryRow(ctx, query, req.UserID).Scan(
		&up.ID,
		&up.Username,
		&up.Email,
		&up.PhoneNo,
		&up.AccCode,
		&up.Bio,
		&up.ImageURL,
		&up.City,
	)

	if err != nil {
		log.Printf("Error fetching user profile: %v", err)
		c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "User not found"})
		return
	}

	// 3. Return the data
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    up,
	})
}

type SignInRequest struct {
	Email string `json:"email" binding:"required"`
	// Password string `json:"password" binding:"required"`
}

type SignInResponse struct {
	ID              int    `json:"id"`
	Username        string `json:"username"`
	UserType        string `json:"UserType"`
	UserType_id     string `json:"UserType_id"`
	Email           string `json:"email"`
	PhoneNo         string `json:"phoneno"`
	Address         string `json:"address"`
	City            string `json:"city"`
	State_territory string `json:"state_territory"`
	AccCode         string `json:"acccode"`
	ImageURL        string `json:"image_url"`
}

type Otp_struct struct {
	Email    string `json:"email"`
	Phone_no string `json:"Phone_no"`
	OTP      string `json:"OTP"`
}

func SignIn(c *gin.Context) {
	var req SignInRequest
	ctx := c.Request.Context()

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Email is required"})
		return
	}

	// 1. Fetch User & Security Limits
	query := `
    SELECT 
        u.id, u.username, COALESCE(r.role_name, 'user'), u.email, 
        COALESCE(u.phoneno, ''), COALESCE(u.address, ''), 
        COALESCE(u.city, ''), COALESCE(u.image_url, ''),
        u.retry_cnt_lmt, u.retrycnt_updated_on
    FROM users u
    LEFT JOIN user_roles ur ON ur.user_id = u.id
    LEFT JOIN roles r ON r.id = ur.role_id
    WHERE LOWER(u.email) = LOWER($1) AND u.is_active = true
    ORDER BY r.role_name ASC
    LIMIT 1`

	var user SignInResponse
	var retryLmt int
	var retryTime sql.NullTime

	err := dal.DB.QueryRow(ctx, query, strings.ToLower(req.Email)).Scan(
		&user.ID, &user.Username, &user.UserType, &user.Email,
		&user.PhoneNo, &user.Address, &user.City, &user.ImageURL,
		&retryLmt, &retryTime,
	)

	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"success": false, "message": "User not found or inactive"})
		return
	}

	// 2. Check Global Settings
	var enableOtp bool
	_ = dal.DB.QueryRow(ctx, "SELECT COALESCE(enable_otp, true) FROM tbl_general_settings LIMIT 1").Scan(&enableOtp)

	if !enableOtp {
		// PATH A: OTP Disabled -> Success
		c.JSON(http.StatusOK, gin.H{"success": true, "otp_skipped": true, "data": user})
		return
	}

	// 3. Handle OTP Generation & Retries
	now := time.Now()
	if retryLmt <= 0 && retryTime.Valid && now.Sub(retryTime.Time) < 5*time.Minute {
		c.JSON(http.StatusTooManyRequests, gin.H{"success": false, "message": "Too many attempts. Please wait 5 minutes."})
		return
	}

	otpCode := GenerateOTP()
	expiresAt := now.Add(10 * time.Minute)

	// Log OTP and Update Retry Counter
	tx, _ := dal.DB.Begin(ctx)
	defer tx.Rollback(ctx)

	tx.Exec(ctx, "UPDATE users SET retry_cnt_lmt = retry_cnt_lmt - 1, retrycnt_updated_on = NOW() WHERE id = $1", user.ID)
	tx.Exec(ctx, "INSERT INTO otp_log (userid, emailid, otp, expires_at) VALUES ($1, $2, $3, $4)", user.ID, user.Email, otpCode, expiresAt)

	tx.Commit(ctx)
	otpData := Otp_struct{
		Email:    user.Email,
		Phone_no: user.PhoneNo,
		OTP:      otpCode,
	}

	err = SendOTP(otpData) // Call your mail function
	if err != nil {
		// THIS LOG IS CRITICAL - It will tell you why the mail failed in the terminal
		log.Printf("❌ MAIL ERROR for %s: %v", user.Email, err)

		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "User identified, but failed to send email. Check SMTP settings.",
		})
		return
	}
	// In production: SendEmail(user.Email, otpCode)
	fmt.Printf("DEBUG: OTP for %s is %s\n", user.Email, otpCode)

	c.JSON(http.StatusOK, gin.H{"success": true, "otp_skipped": false, "message": "OTP sent to email"})
}

// ============================================================
// 2. VERIFY OTP
// ============================================================
func Verify_OTP(c *gin.Context) {
	var req struct {
		Email string `json:"email" binding:"required"`
		OTP   string `json:"otp" binding:"required"`
	}
	ctx := c.Request.Context()

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Email and OTP are required"})
		return
	}

	// 1. Check OTP
	var logID int
	var userID int
	query := `SELECT id, userid FROM otp_log WHERE emailid = $1 AND otp = $2 AND is_verified = false AND expires_at > NOW() LIMIT 1`

	err := dal.DB.QueryRow(ctx, query, req.Email, req.OTP).Scan(&logID, &userID)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"success": false, "message": "Invalid or expired code"})
		return
	}

	// 2. Update status
	dal.DB.Exec(ctx, "UPDATE otp_log SET is_verified = true, verified_at = NOW() WHERE id = $1", logID)
	dal.DB.Exec(ctx, "UPDATE users SET retry_cnt_lmt = 5 WHERE id = $1", userID)

	// 3. Fetch Basic User Data (Removed problematic columns: address, acccode, state_territory, image_url)
	userQuery := `
		SELECT 
			u.id, 
			u.username, 
			u.email, 
			COALESCE(r.role_name, 'user') as role_name,
			COALESCE(u.phoneno, ''),
			COALESCE(u.city, '')
		FROM users u
		LEFT JOIN user_roles ur ON ur.user_id = u.id
		LEFT JOIN roles r ON r.id = ur.role_id
		WHERE u.id = $1
		ORDER BY r.role_name ASC
		LIMIT 1`

	var user SignInResponse 
	err = dal.DB.QueryRow(ctx, userQuery, userID).Scan(
		&user.ID,
		&user.Username,
		&user.Email,
		&user.UserType, // This returns 'admin' correctly
		&user.PhoneNo,
		&user.City,
	)

	if err != nil {
		log.Printf("Error fetching user after OTP: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "User details not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "OTP verified successfully",
		"data":    user,
	})
}
// ============================================================
// 3. CREATE / UPDATE USER (HYBRID)
// ============================================================
func Create_Cususer(c *gin.Context) {
	ctx := c.Request.Context()
	username := c.PostForm("username")
	email := strings.ToLower(c.PostForm("email"))
	phoneno := c.PostForm("phoneno")
	usertype := c.PostForm("usertype")

	tx, err := dal.DB.Begin(ctx)
	if err != nil {
		return
	}
	defer tx.Rollback(ctx)

	var lastID int
	query := `INSERT INTO users (username, email, phoneno, is_active) VALUES ($1, $2, $3, true) RETURNING id`
	err = tx.QueryRow(ctx, query, username, email, phoneno).Scan(&lastID)
	if err != nil {
		c.JSON(409, gin.H{"success": false, "message": "Email already registered"})
		return
	}

	// Role Assignment
	var roleID int
	_ = tx.QueryRow(ctx, "SELECT id FROM roles WHERE LOWER(role_name) = $1", strings.ToLower(usertype)).Scan(&roleID)
	tx.Exec(ctx, "INSERT INTO user_roles (user_id, role_id) VALUES ($1, $2)", lastID, roleID)

	tx.Commit(ctx)
	c.JSON(200, gin.H{"success": true, "message": "Account created"})
}

func Update_Cususer(c *gin.Context) {
	ctx := c.Request.Context()
	id := c.PostForm("id")
	username := c.PostForm("username")
	bio := c.PostForm("bio")
	city := c.PostForm("city")

	file, err := c.FormFile("image")
	var imagePath string
	if err == nil {
		// SEQUENTIAL NAMING: user_ID_TIMESTAMP.ext
		ext := filepath.Ext(file.Filename)
		imagePath = fmt.Sprintf("uploads/users/user_%s_%d%s", id, time.Now().Unix(), ext)
		os.MkdirAll("uploads/users", 0755)
		c.SaveUploadedFile(file, imagePath)
	} else {
		imagePath = c.PostForm("existing_image")
	}

	query := `UPDATE users SET username=$1, bio=$2, city=$3, image_url=$4, updated_at=NOW() WHERE id=$5`
	_, err = dal.DB.Exec(ctx, query, username, bio, city, imagePath, id)

	if err != nil {
		c.JSON(500, gin.H{"success": false, "message": "Update failed"})
		return
	}
	c.JSON(200, gin.H{"success": true})
}

// ============================================================
// 4. SOFT DELETE & LOGOUT
// ============================================================
func Delete_Cususer(c *gin.Context) {
	// Soft delete to preserve Ledger data
	var body struct {
		ID interface{} `json:"id"`
	}
	c.ShouldBindJSON(&body)

	query := `UPDATE users SET is_active = false, updated_at = NOW() WHERE id = $1`
	_, err := dal.DB.Exec(c.Request.Context(), query, AnyToInt(body.ID))

	if err != nil {
		c.JSON(500, gin.H{"success": false, "message": "Delete failed"})
		return
	}
	c.JSON(200, gin.H{"success": true})
}

func Logout(c *gin.Context) {
	// Updates last active time
	userid := c.PostForm("userid")
	dal.DB.Exec(c.Request.Context(), "UPDATE users SET updated_at = NOW() WHERE id = $1", userid)
	c.JSON(200, gin.H{"success": true, "message": "Logged out"})
}

// ============================================================
// 5. ADMIN UTILS
// ============================================================
func GetAllUsers(c *gin.Context) {
	query := `
		SELECT u.id, u.username, u.email, COALESCE(u.phoneno, ''), r.role_name, u.is_active
		FROM users u
		LEFT JOIN user_roles ur ON ur.user_id = u.id
		LEFT JOIN roles r ON r.id = ur.role_id
		ORDER BY u.id DESC`

	rows, _ := dal.DB.Query(c.Request.Context(), query)
	defer rows.Close()

	users := []interface{}{}
	for rows.Next() {
		var id int
		var name, email, phone, role string
		var active bool
		rows.Scan(&id, &name, &email, &phone, &role, &active)
		users = append(users, gin.H{"id": id, "username": name, "email": email, "phone": phone, "role": role, "is_active": active})
	}
	c.JSON(200, gin.H{"success": true, "data": users})
}

// ────────────────────────────────────────────────
// ADMIN: Update User Role
// ────────────────────────────────────────────────

type UpdateUserRoleRequest struct {
	UserID int    `json:"user_id"`
	Role   string `json:"role"`
}

func UpdateUserRole(c *gin.Context) {
	var req UpdateUserRoleRequest
	ctx := c.Request.Context()

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid Request"})
		return
	}

	// Get role ID
	var roleID int
	err := dal.DB.QueryRow(ctx, "SELECT id FROM roles WHERE role_name = $1", req.Role).Scan(&roleID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid role"})
		return
	}

	// Check if user_roles entry exists
	var count int
	dal.DB.QueryRow(ctx, "SELECT COUNT(*) FROM user_roles WHERE user_id = $1", req.UserID).Scan(&count)

	if count > 0 {
		_, err = dal.ExecNonQuery(ctx,
			"UPDATE user_roles SET role_id = $1 WHERE user_id = $2", roleID, req.UserID)
	} else {
		_, err = dal.ExecNonQuery(ctx,
			"INSERT INTO user_roles (user_id, role_id) VALUES ($1, $2)", req.UserID, roleID)
	}

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Failed to update role"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "User role updated successfully",
	})
}
