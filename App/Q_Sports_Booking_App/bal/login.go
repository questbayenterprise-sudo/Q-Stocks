package bal

import (
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"time"

	"github.com/gin-gonic/gin"
	dal "github.com/qsports/q-sports-booking-app/dal"
)

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

func Logout(c *gin.Context) {
	// session, _ := store.Get(r, "auth-session")
	// session.Options.MaxAge = -1 // delete session
	// session.Save(r, w)
	userid := c.PostForm("userid")
	query1 := "UPDATE users set updated_at= now() where id in (&1)"

	rows, err := dal.ExecNonQuery(c.Request.Context(), query1, userid)

	if err != nil && rows == 0 {
		c.JSON(http.StatusOK, gin.H{"success": false, "message": "Database error"})
		return
		//return err
	} else {
		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"message": "Logout Successfuly",
		})
		return
	}
}

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

func Create_Cususer(c *gin.Context) {
	ctx := c.Request.Context()

	// 1. Get Form Fields
	// Note: You can add validation here (e.g., check if email is empty)
	username := c.PostForm("username")
	email := c.PostForm("email")
	phoneno := c.PostForm("phoneno")
	acccode := c.PostForm("acccode")
	usertype := c.PostForm("usertype")
	address := c.PostForm("address")
	city := c.PostForm("city")
	state_territory := c.PostForm("state_territory")

	// Basic Validation
	if usertype != "Customer" {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid user type"})
		return
	}

	if email == "" || username == "" {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Username and Email are required"})
		return
	}

	// ────────────────────────────────────────────────
	// START TRANSACTION
	// ────────────────────────────────────────────────
	tx, err := dal.DB.Begin(ctx)
	if err != nil {
		log.Printf("Transaction Start Error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "DB Transaction Error"})
		return
	}

	// Rollback automatically if function returns before Commit
	defer tx.Rollback(ctx)

	// 2. Check if Email already exists
	// Since the DB schema has UNIQUE constraint, we check this first for a cleaner error message
	var count int
	checkQuery := `SELECT COUNT(*) FROM users WHERE email = $1`
	err = tx.QueryRow(ctx, checkQuery, email).Scan(&count)
	if err != nil {
		log.Printf("Email check error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Error checking existing user"})
		return
	}

	if count > 0 {
		c.JSON(http.StatusConflict, gin.H{
			"success": false,
			"message": "MailID already exists",
		})
		return
	}

	// 3. Insert into users table
	uQuery := `
	INSERT INTO users 
	(username, email, phoneno, acccode, is_active, address, city, state_territory) 
	VALUES ($1, $2, $3, $4, $5, $6, $7, $8) 
	RETURNING id
	`

	var lastID int

	err = tx.QueryRow(ctx, uQuery,
		username,
		email,
		phoneno,
		acccode,
		true,
		address,
		city,
		state_territory,
	).Scan(&lastID)

	if err != nil {
		log.Printf("User Insert Error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to create account",
		})
		return
	}

	//
	// 4. Get role_id for default role = 'user'
	//
	var roleID int
	roleQuery := `SELECT id FROM roles WHERE role_name = 'user' LIMIT 1`

	err = tx.QueryRow(ctx, roleQuery).Scan(&roleID)
	if err != nil {
		log.Printf("Role Fetch Error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Default role not configured",
		})
		return
	}

	//
	// 5. Insert into user_roles mapping table
	//
	mapQuery := `
	INSERT INTO user_roles (user_id, role_id)
	VALUES ($1, $2)
	`

	_, err = tx.Exec(ctx, mapQuery, lastID, roleID)
	if err != nil {
		log.Printf("User Role Insert Error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to assign user role",
		})
		return
	}
	// 4. COMMIT TRANSACTION
	if err := tx.Commit(ctx); err != nil {
		log.Printf("Commit Error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Final save failed"})
		return
	}

	// 5. Success Response
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"status":  http.StatusOK,
		"message": "Account Created Successfully",
		"data": gin.H{
			"id": lastID,
		},
	})
}

func Update_Cususer(c *gin.Context) {
	ctx := c.Request.Context()

	// 1. Get Fields (Including ID)
	id := c.PostForm("id")
	username := c.PostForm("username")
	email := c.PostForm("email")
	phoneno := c.PostForm("phoneno")
	acccode := c.PostForm("acccode")
	city := c.PostForm("city")
	bio := c.PostForm("bio")

	if id == "" {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "User ID is required"})
		return
	}
	var imagePath string
	file, err := c.FormFile("image") // Ensure Flutter sends key as "image"

	if err == nil {
		// New image uploaded
		uploadDir := "uploads/users"

		// Check if directory exists
		if _, err := os.Stat(uploadDir); os.IsNotExist(err) {
			// If it doesn't exist, try to create it
			err := os.MkdirAll(uploadDir, 0755) // 0755 is standard for public-readable folders
			if err != nil {
				log.Printf("Directory creation failed: %v", err)
				c.JSON(500, gin.H{"success": false, "message": "Could not create upload directory"})
				return
			}
		}
		// Use ID as filename + original extension
		ext := filepath.Ext(file.Filename)
		filename := fmt.Sprintf("%s%s", id, ext)
		imagePath = filepath.Join(uploadDir, filename)

		// Save the file
		if err := c.SaveUploadedFile(file, imagePath); err != nil {
			log.Printf("File Save Error: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Failed to save image"})
			return
		}
	}
	// ────────────────────────────────────────────────
	// START TRANSACTION
	// ────────────────────────────────────────────────
	tx, err := dal.DB.Begin(ctx)
	if err != nil {
		log.Printf("Transaction Start Error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "DB Transaction Error"})
		return
	}
	defer tx.Rollback(ctx)

	// 2. Check for Email Conflict
	// (Ensure the new email isn't already taken by someone ELSE)
	var count int
	checkQuery := `SELECT COUNT(*) FROM users WHERE email = $1 AND id != $2`
	err = tx.QueryRow(ctx, checkQuery, email, id).Scan(&count)
	if err != nil {
		log.Printf("Email check error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Error validating email"})
		return
	}
	if count > 0 {
		c.JSON(http.StatusConflict, gin.H{"success": false, "message": "Email already in use by another account"})
		return
	}

	// 3. Update User
	var result interface{ RowsAffected() int64 }
	if imagePath != "" {
		uQuery := `UPDATE users
				   SET username = $1, email = $2, phoneno = $3, acccode = $4, city = $5, bio = $6, image_url = $7, updated_at = CURRENT_TIMESTAMP
				   WHERE id = $8`
		result, err = tx.Exec(ctx, uQuery, username, email, phoneno, acccode, city, bio, imagePath, id)
	} else {
		uQuery := `UPDATE users
				   SET username = $1, email = $2, phoneno = $3, acccode = $4, city = $5, bio = $6, updated_at = CURRENT_TIMESTAMP
				   WHERE id = $7`
		result, err = tx.Exec(ctx, uQuery, username, email, phoneno, acccode, city, bio, id)
	}
	if err != nil {
		log.Printf("User Update Error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Failed to update account"})
		return
	}

	// Check if any row was actually updated
	rowsAffected := result.RowsAffected()
	if rowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "User not found"})
		return
	}

	// 4. COMMIT TRANSACTION
	if err := tx.Commit(ctx); err != nil {
		log.Printf("Commit Error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Final save failed"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Account Updated Successfully",
	})
}

func Delete_Cususer(c *gin.Context) {
	ctx := c.Request.Context()

	// 1. Get ID from params, form, or JSON body
	id := c.Param("id")
	if id == "" {
		id = c.PostForm("id")
	}
	if id == "" {
		var body struct {
			ID string `json:"id"`
		}
		if err := c.ShouldBindJSON(&body); err == nil {
			id = body.ID
		}
	}

	if id == "" {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "User ID is required"})
		return
	}

	// ────────────────────────────────────────────────
	// START TRANSACTION
	// ────────────────────────────────────────────────
	tx, err := dal.DB.Begin(ctx)
	if err != nil {
		log.Printf("Transaction Start Error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "DB Transaction Error"})
		return
	}
	defer tx.Rollback(ctx)

	// 2. Delete User
	dQuery := `DELETE FROM users WHERE id = $1`

	result, err := tx.Exec(ctx, dQuery, id)
	if err != nil {
		log.Printf("User Delete Error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Failed to delete account"})
		return
	}

	// Check if the user existed
	if result.RowsAffected() == 0 {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "User not found"})
		return
	}

	// 3. COMMIT TRANSACTION
	if err := tx.Commit(ctx); err != nil {
		log.Printf("Commit Error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Deletion failed"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "User deleted successfully",
	})
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

	// 1. Bind JSON request
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Email and Password are required"})
		return
	}

	// 2. Query the database
	// Note: In a production app, you should use bcrypt to verify the password.
	// This query assumes you have a password column in your users table.
	query := `
	select usr.id ,username ,role_id as UserType ,role_name as UserType_id,email ,phoneno
	,acccode ,address ,city ,state_territory
	--, COALESCE(image_url, '') 
	 from users usr 
		left join user_roles usr_rl on usr_rl.user_id=usr.id
		left join roles rl on rl.id = usr_rl.role_id
		where is_active=TRUE and usr.email = $1
	`

	var user SignInResponse
	err := dal.DB.QueryRow(ctx, query, req.Email).Scan(
		&user.ID,
		&user.Username,
		&user.UserType,
		&user.UserType_id,
		&user.Email,
		&user.PhoneNo,
		&user.AccCode,
		&user.Address,
		&user.City,
		&user.State_territory,
	)

	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"status":  http.StatusUnauthorized,
			"message": "Invalid email",
		})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    user,
	})
}

func Send_OTP(c *gin.Context) {
	var Otp_data Otp_struct

	// Bind JSON
	if err := c.ShouldBindJSON(&Otp_data); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Email is required",
		})
		return
	}

	// Check if OTP verification is enabled in general settings
	var enableVerifyOtp bool
	otpCheckErr := dal.DB.QueryRow(c.Request.Context(),
		"SELECT COALESCE(enable_verify_otp, true) FROM tbl_general_settings LIMIT 1").Scan(&enableVerifyOtp)
	if otpCheckErr == nil && !enableVerifyOtp {
		// OTP is disabled — return user data directly for auto-login
		var uid int64
		var username, usertype string
		err := dal.DB.QueryRow(c.Request.Context(), `
			SELECT u.id, u.username, COALESCE(r.role_name, 'user') AS usertype
			FROM users u
			LEFT JOIN user_roles ur ON ur.user_id = u.id
			LEFT JOIN roles r ON r.id = ur.role_id
			WHERE u.email = $1
			LIMIT 1`, Otp_data.Email).Scan(&uid, &username, &usertype)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{
				"success": false,
				"message": "User not found",
			})
			return
		}
		c.JSON(http.StatusOK, gin.H{
			"success":     true,
			"otp_skipped": true,
			"message":     "OTP verification is disabled",
			"data": gin.H{
				"id":       uid,
				"username": username,
				"usertype": usertype,
			},
		})
		return
	}

	// Generate OTP
	Otp_data.OTP = GenerateOTP()

	var (
		id                  int64
		userID              *int64
		phone               string
		retry_cnt_lmt       int
		retrycnt_updated_on sql.NullTime
	)

	// Check user
	queryUser := `
		SELECT id, phoneno, retry_cnt_lmt, retrycnt_updated_on
		FROM users
		WHERE email = $1
	`

	var uid int64
	err := dal.DB.QueryRow(
		c.Request.Context(),
		queryUser,
		Otp_data.Email,
	).Scan(&uid, &phone, &retry_cnt_lmt, &retrycnt_updated_on)

	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"message": "User not found",
		})
		return
	}

	userID = &uid
	Otp_data.Phone_no = phone

	// Handle timestamp
	var createdAt time.Time
	if retrycnt_updated_on.Valid {
		createdAt = retrycnt_updated_on.Time
	} else {
		createdAt = time.Now().Add(-10 * time.Minute)
	}

	now := time.Now()
	threshold := createdAt.Add(5 * time.Minute)
	remaining := threshold.Sub(now)

	// If retry count available
	if retry_cnt_lmt > 0 {

		update_query := `
			UPDATE users
			SET retry_cnt_lmt = retry_cnt_lmt - 1,
				retrycnt_updated_on = now()
			WHERE email = $1
			  AND retry_cnt_lmt > 0
		`

		rows, err := dal.ExecNonQuery(c.Request.Context(), update_query, Otp_data.Email)

		if err != nil || rows == 0 {
			c.JSON(http.StatusUnauthorized, gin.H{
				"success": false,
				"message": "Failed to update retry count",
			})
			return
		}

		// Insert OTP log
		queryInsert := `
			INSERT INTO otp_log (userid, emailid, phoneno, otp)
			VALUES ($1, $2, $3, $4)
			RETURNING id
		`

		err = dal.DB.QueryRow(
			c.Request.Context(),
			queryInsert,
			userID,
			Otp_data.Email,
			Otp_data.Phone_no,
			Otp_data.OTP,
		).Scan(&id)

		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{
				"success": false,
				"message": "Failed to insert OTP",
			})
			return
		}

		// Send OTP
		err = SendOTP(Otp_data)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{
				"success": false,
				"message": "Failed to send OTP",
			})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"message": "OTP Sent successfully",
		})
		return
	}

	// If retry limit reached
	if retry_cnt_lmt == 0 {

		if now.After(threshold) {

			retry_cnt_query := `
				UPDATE users
				SET retry_cnt_lmt = (
					SELECT retry_count_limit
					FROM tbl_general_settings
					LIMIT 1
				),
				retrycnt_updated_on = now()
				WHERE email = $1
			`

			rows, err := dal.ExecNonQuery(c.Request.Context(), retry_cnt_query, Otp_data.Email)

			if err != nil || rows == 0 {
				c.JSON(http.StatusInternalServerError, gin.H{
					"success": false,
					"message": "Database error",
				})
				return
			}

			c.JSON(http.StatusOK, gin.H{
				"success": true,
				"message": "Retry limit reset. Please request OTP again.",
			})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"success": false,
			"message": fmt.Sprintf(
				"Send OTP retry limit reached, try after %v",
				remaining.Round(time.Minute),
			),
		})
		return
	}

	c.JSON(http.StatusUnauthorized, gin.H{
		"success": false,
		"message": "Failed to send OTP",
	})
}

func Verify_OTP(c *gin.Context) {
	var Otp_data Otp_struct
	ctx := c.Request.Context()

	// 1. Bind JSON
	if err := c.ShouldBindJSON(&Otp_data); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Email and OTP are required",
		})
		return
	}

	// 2. Verify OTP
	result := Verify_OTP_auth(ctx, Otp_data)
	if result != "true" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid or expired OTP",
		})
		return
	}

	// 3. Reset retry count to general settings limit after successful OTP
	resetQuery := `
		UPDATE users
		SET retry_cnt_lmt = COALESCE(
			(SELECT retry_count_limit FROM tbl_general_settings LIMIT 1), 5
		),
		retrycnt_updated_on = NOW()
		WHERE email = $1
	`
	_, _ = dal.ExecNonQuery(ctx, resetQuery, Otp_data.Email)

	// 4. Fetch user details
	var (
		id       int64
		username string
		usertype string
	)

	query := `
	SELECT
	u.id,
	u.username,
	r.role_name AS usertype
	FROM users u
	LEFT JOIN user_roles ur ON ur.user_id = u.id
	LEFT JOIN roles r ON r.id = ur.role_id
	WHERE u.email = $1
	LIMIT 1;
	`
	err := dal.DB.QueryRow(ctx, query, Otp_data.Email).
		Scan(&id, &username, &usertype)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "User not found after OTP verification",
		})
		return
	}

	// 5. Return user data
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "OTP verified successfully",
		"data": gin.H{
			"id":       id,
			"username": username,
			"usertype": usertype,
		},
	})
}

// ────────────────────────────────────────────────
// ADMIN: Get All Users
// ────────────────────────────────────────────────

func GetAllUsers(c *gin.Context) {
	ctx := c.Request.Context()

	query := `
		SELECT
			u.id,
			u.username,
			u.email,
			COALESCE(u.phoneno, '') as phoneno,
			COALESCE(r.role_name, 'user') as role,
			u.is_active,
			COALESCE(u.image_url, '') as image_url,
			COALESCE(u.city, '') as city,
			TO_CHAR(u.created_at, 'YYYY-MM-DD') as created_at
		FROM users u
		LEFT JOIN user_roles ur ON ur.user_id = u.id
		LEFT JOIN roles r ON r.id = ur.role_id
		ORDER BY u.id ASC
	`

	rows, err := dal.Query(ctx, query)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Database error"})
		return
	}
	defer rows.Close()

	var users []gin.H
	for rows.Next() {
		var id int
		var username, email, phoneno, role, imageUrl, city, createdAt string
		var isActive bool

		if err := rows.Scan(&id, &username, &email, &phoneno, &role, &isActive, &imageUrl, &city, &createdAt); err != nil {
			continue
		}
		users = append(users, gin.H{
			"id":         id,
			"username":   username,
			"email":      email,
			"phoneno":    phoneno,
			"role":       role,
			"is_active":  isActive,
			"image_url":  imageUrl,
			"city":       city,
			"created_at": createdAt,
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    users,
	})
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
