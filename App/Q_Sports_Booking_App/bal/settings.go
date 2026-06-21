package bal

import (
	"log"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"

	dal "github.com/qsports/q-stocks-app/dal"
)

type Edit_user_profile struct {
	CusUserID   string
	CusUserName string
	Mobno       string
	EmailID     string
	CusUserImg  string
}

type Del_user_profile struct {
	CusUserID string
}

type CusBookHis struct {
	filtertype string
	CusUserID  string
	pageno     int
	pagesize   int
}

type User_pers_settings struct {
	Language    string
	Region      string
	Push_notify bool
	Mail_upd    bool
	Themes      string
	CusUserID   string
}

func User_personal_settings_edit(c *gin.Context) {
	var Edit_user_profileStruct Edit_user_profile
	if err := c.ShouldBindJSON(&Edit_user_profileStruct); err != nil {
		c.JSON(http.StatusOK, gin.H{
			"success": false,
			"status":  http.StatusBadRequest,
			"message": "Invalid Request",
			"data":    nil,
		})
		return
	} else {
		query := "SELECT COUNT(id) FROM users WHERE id = $1 and is_active = true "
		row := dal.QueryRow(c.Request.Context(), query, Edit_user_profileStruct.CusUserID)

		var count int
		err := row.Scan(&count)
		if err != nil {
			c.JSON(http.StatusOK, gin.H{"success": false, "message": "Database error"})
			return
			//return err
		} else if count != 0 {

			query1 := `UPDATE users SET username = $1,
						email = $2, phoneno = $3 WHERE id = $4 AND (
						username IS DISTINCT FROM $1 OR
						email IS DISTINCT FROM $2 OR
						phoneno IS DISTINCT FROM $3
						);`

			rows, err := dal.ExecNonQuery(c.Request.Context(), query1, Edit_user_profileStruct.CusUserName, Edit_user_profileStruct.EmailID, Edit_user_profileStruct.Mobno, Edit_user_profileStruct.CusUserID)

			if err != nil && rows == 0 {
				c.JSON(http.StatusOK, gin.H{"success": false, "message": "Database error"})
				return
				//return err
			} else {
				c.JSON(http.StatusOK, gin.H{
					"success": true,
					"message": "User Details update Successfuly",
				})
				return
			}
		} else {
			c.JSON(http.StatusOK, gin.H{
				"success": true,
				"message": "User Not Exists",
			})
			return
		}
	}
}

func Del_cus_user(c *gin.Context) {
	var Del_user_profilestruct Del_user_profile
	if err := c.ShouldBind(&Del_user_profilestruct); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid request JSON"})
		return
	} else {
		query := "update users set is_active = FALSE where id in ($1) and is_active = true"
		rows, err := dal.ExecNonQuery(c.Request.Context(), query, Del_user_profilestruct.CusUserID)

		if err != nil && rows == 0 {
			c.JSON(http.StatusOK, gin.H{"success": false, "message": "Database error"})
			return
			//return err
		} else {
			c.JSON(http.StatusOK, gin.H{
				"success": true,
				"message": "User Details Deleted Successfuly",
			})
			return
		}
	}
}

func Customer_booking_history(c *gin.Context) {

	var CusBookHisStruct CusBookHis
	if err := c.ShouldBindJSON(&CusBookHisStruct); err != nil {
		c.JSON(http.StatusOK, gin.H{
			"success": false,
			"status":  http.StatusBadRequest,
			"message": "Invalid Request",
			"data":    nil,
		})
	} else {
		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"status":  http.StatusOK,
			"message": "Request handled successfully",
			"data":    nil,
		})
	}
}

func Customer_current_booking(c *gin.Context) {
	if c.PostForm("CusUserID") != "" {
		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"status":  http.StatusOK,
			"message": "Request handled successfully",
			"data":    nil,
		})
	} else {
		c.JSON(http.StatusOK, gin.H{
			"success": false,
			"status":  http.StatusBadRequest,
			"message": "Invalid Request",
			"data":    nil,
		})
	}
}

// --- Request/Response structs for Get/Update UserSettings ---

type UserSettingsRequest struct {
	UserID string `json:"user_id" binding:"required"`
}

type UserSettingsResponse struct {
	ID                int    `json:"id"`
	UserID            int    `json:"user_id"`
	LanguageType      string `json:"language_type"`
	Region            string `json:"region"`
	PushNotifications bool   `json:"push_notifications"`
	EmailUpdates      bool   `json:"email_updates"`
	Themes            string `json:"themes"`
}

type UpdateUserSettingsRequest struct {
	UserID            string `json:"user_id" binding:"required"`
	PushNotifications bool   `json:"push_notifications"`
	EmailUpdates      bool   `json:"email_updates"`
}

// --- GET USER SETTINGS ---
func Get_UserSettings(c *gin.Context) {
	var req UserSettingsRequest
	ctx := c.Request.Context()

	// 1. Bind the incoming JSON request
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid Request"})
		return
	}

	// 2. SQL Query to get user settings
	query := `
		SELECT
			id,
			user_id,
			COALESCE(language_type, '') as language_type,
			COALESCE(region, '') as region,
			COALESCE(push_notify, true) as push_notify,
			COALESCE(mail_upd, true) as mail_upd,
			COALESCE(themes, 'light') as themes
		FROM user_settings
		WHERE user_id = $1 AND isdelete = 0
	`

	var us UserSettingsResponse
	err := dal.DB.QueryRow(ctx, query, req.UserID).Scan(
		&us.ID,
		&us.UserID,
		&us.LanguageType,
		&us.Region,
		&us.PushNotifications,
		&us.EmailUpdates,
		&us.Themes,
	)

	if err != nil {
		// No settings row exists — insert default settings for this user
		insertQuery := `
			INSERT INTO user_settings (user_id, language_type, region, push_notify, mail_upd, themes)
			VALUES ($1, 'English', '', true, true, 'light')
			RETURNING id, user_id, language_type, region, push_notify, mail_upd, themes
		`
		err2 := dal.DB.QueryRow(ctx, insertQuery, req.UserID).Scan(
			&us.ID,
			&us.UserID,
			&us.LanguageType,
			&us.Region,
			&us.PushNotifications,
			&us.EmailUpdates,
			&us.Themes,
		)
		if err2 != nil {
			log.Printf("Error creating default user settings: %v", err2)
			c.JSON(http.StatusOK, gin.H{"success": false, "message": "Database error"})
			return
		}
	}

	// 3. Return the data
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    us,
	})
}

// --- UPDATE USER SETTINGS ---
func Update_UserSettings(c *gin.Context) {
	var req UpdateUserSettingsRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusOK, gin.H{
			"success": false,
			"status":  http.StatusBadRequest,
			"message": "Invalid Request",
			"data":    nil,
		})
		return
	}

	query := `UPDATE user_settings SET push_notify = $1, mail_upd = $2, updated_at = CURRENT_TIMESTAMP
				WHERE user_id = $3 AND isdelete = 0 AND (
				push_notify IS DISTINCT FROM $1 OR
				mail_upd IS DISTINCT FROM $2
				);`

	rows, err := dal.ExecNonQuery(c.Request.Context(), query, req.PushNotifications, req.EmailUpdates, req.UserID)

	if err != nil && rows == 0 {
		c.JSON(http.StatusOK, gin.H{"success": false, "message": "Database error"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "User Settings Update Successfuly",
	})
}

// --- GET CITIES ---
func Get_Cities(c *gin.Context) {
	ctx := c.Request.Context()

	query := `SELECT name FROM cities WHERE is_active = true AND state = 'Tamil Nadu' ORDER BY name`

	rows, err := dal.DB.Query(ctx, query)
	if err != nil {
		log.Printf("Error fetching cities: %v", err)
		c.JSON(http.StatusOK, gin.H{"success": false, "message": "Database error"})
		return
	}
	defer rows.Close()

	var cities []string
	for rows.Next() {
		var name string
		if err := rows.Scan(&name); err != nil {
			log.Printf("Error scanning city: %v", err)
			continue
		}
		cities = append(cities, name)
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    cities,
	})
}

// --- INSERT CITY (if not exists) ---
func Insert_City(c *gin.Context) {
	var req struct {
		Name      string  `json:"name" binding:"required"`
		State     string  `json:"state"`
		Latitude  float64 `json:"latitude"`
		Longitude float64 `json:"longitude"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "City name is required"})
		return
	}

	ctx := c.Request.Context()

	// Normalize: trim and capitalize first letter
	name := strings.TrimSpace(req.Name)
	if len(name) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "City name is required"})
		return
	}
	name = strings.ToUpper(name[:1]) + strings.ToLower(name[1:])

	state := req.State
	if state == "" {
		state = "Tamil Nadu"
	}

	// Check if city already exists (case-insensitive)
	var existingId int
	var existingName string
	err := dal.DB.QueryRow(ctx,
		`SELECT id, name FROM cities WHERE LOWER(name) = LOWER($1) AND state = $2 AND is_active = true`,
		name, state,
	).Scan(&existingId, &existingName)

	if err == nil {
		// City already exists
		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"data":    gin.H{"id": existingId, "name": existingName},
			"message": "City already exists",
		})
		return
	}

	// Insert new city
	var newId int
	err = dal.DB.QueryRow(ctx,
		`INSERT INTO cities (name, state, latitude, longitude) VALUES ($1, $2, $3, $4) RETURNING id`,
		name, state, req.Latitude, req.Longitude,
	).Scan(&newId)
	if err != nil {
		log.Printf("Error inserting city: %v", err)
		c.JSON(http.StatusOK, gin.H{"success": false, "message": "Failed to add city"})
		return
	}

	log.Printf("[CITY] Added new city: %s (%s), id=%d", name, state, newId)
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    gin.H{"id": newId, "name": name},
		"message": "City added successfully",
	})
}

// --- UPDATE USER LOCATION ---
type UpdateLocationRequest struct {
	UserID    string  `json:"user_id" binding:"required"`
	City      string  `json:"city"`
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
}

func Update_UserLocation(c *gin.Context) {
	var req UpdateLocationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid Request"})
		return
	}

	query := `UPDATE users SET city = $1, latitude = $2, longitude = $3, updated_at = CURRENT_TIMESTAMP
			  WHERE id = $4 AND is_active = true`

	rows, err := dal.ExecNonQuery(c.Request.Context(), query, req.City, req.Latitude, req.Longitude, req.UserID)
	if err != nil && rows == 0 {
		log.Printf("Error updating user location: %v", err)
		c.JSON(http.StatusOK, gin.H{"success": false, "message": "Database error"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Location Updated Successfully",
	})
}

func Update_user_personal_seettings(c *gin.Context) {
	var User_pers_settings_struct User_pers_settings
	if err := c.ShouldBind(&User_pers_settings_struct); err != nil {
		c.JSON(http.StatusOK, gin.H{
			"success": false,
			"status":  http.StatusBadRequest,
			"message": "Invalid Request",
			"data":    nil,
		})
		return
	} else {
		query := `UPDATE user_settings SET language_type = $1,
						region = $2, push_notify = $3,mail_upd = $4,themes = $5 WHERE user_id = $6 and isdelete = 0  AND (
						language_type IS DISTINCT FROM $1 OR
						region IS DISTINCT FROM $2 OR
						push_notify IS DISTINCT FROM $3 OR
						mail_upd IS DISTINCT FROM $4 OR
						themes IS DISTINCT FROM $5
						);`

		rows, err := dal.ExecNonQuery(c.Request.Context(), query, User_pers_settings_struct.Language, User_pers_settings_struct.Region, User_pers_settings_struct.Push_notify, User_pers_settings_struct.Mail_upd, User_pers_settings_struct.Themes, User_pers_settings_struct.CusUserID)

		if err != nil && rows == 0 {
			c.JSON(http.StatusOK, gin.H{"success": false, "message": "Database error"})
			return
			//return err
		} else {
			c.JSON(http.StatusOK, gin.H{
				"success": true,
				"message": "User Settings Update Successfuly",
			})
			return
		}
	}
}

// --- GET ADMIN SETTINGS ---
func Get_AdminSettings(c *gin.Context) {
	ctx := c.Request.Context()

	var enableOtp, enableSkipLogin, enablePayment bool
	var retryLimit int

	err := dal.DB.QueryRow(ctx, `
		SELECT COALESCE(enable_verify_otp, true),
		       COALESCE(enable_skip_login, true),
		       COALESCE(retry_count_limit, 3),
		       COALESCE(enable_payment, false)
		FROM tbl_general_settings LIMIT 1
	`).Scan(&enableOtp, &enableSkipLogin, &retryLimit, &enablePayment)

	if err != nil {
		c.JSON(http.StatusOK, gin.H{"success": false, "message": "Settings not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"enable_verify_otp": enableOtp,
			"enable_skip_login": enableSkipLogin,
			"retry_count_limit": retryLimit,
			"enable_payment":    enablePayment,
		},
	})
}

// --- UPDATE ADMIN SETTINGS ---
type UpdateAdminSettingsRequest struct {
	EnableVerifyOtp *bool `json:"enable_verify_otp"`
	EnableSkipLogin *bool `json:"enable_skip_login"`
	RetryCountLimit *int  `json:"retry_count_limit"`
	EnablePayment   *bool `json:"enable_payment"`
}

func Update_AdminSettings(c *gin.Context) {
	var req UpdateAdminSettingsRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid Request"})
		return
	}

	ctx := c.Request.Context()

	if req.EnableVerifyOtp != nil {
		if _, err := dal.ExecNonQuery(ctx,
			"UPDATE tbl_general_settings SET enable_verify_otp = $1", *req.EnableVerifyOtp); err != nil {
			c.JSON(http.StatusOK, gin.H{"success": false, "message": "Database error"})
			return
		}
	}
	if req.EnableSkipLogin != nil {
		if _, err := dal.ExecNonQuery(ctx,
			"UPDATE tbl_general_settings SET enable_skip_login = $1", *req.EnableSkipLogin); err != nil {
			c.JSON(http.StatusOK, gin.H{"success": false, "message": "Database error"})
			return
		}
	}
	if req.RetryCountLimit != nil {
		if _, err := dal.ExecNonQuery(ctx,
			"UPDATE tbl_general_settings SET retry_count_limit = $1", *req.RetryCountLimit); err != nil {
			c.JSON(http.StatusOK, gin.H{"success": false, "message": "Database error"})
			return
		}
	}
	if req.EnablePayment != nil {
		if _, err := dal.ExecNonQuery(ctx,
			"UPDATE tbl_general_settings SET enable_payment = $1", *req.EnablePayment); err != nil {
			c.JSON(http.StatusOK, gin.H{"success": false, "message": "Database error"})
			return
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Admin settings updated",
	})
}

// ────────────────────────────────────────────────
// VENUE-USER MAPPING
// ────────────────────────────────────────────────

func GetVenueMappings(c *gin.Context) {
	ctx := c.Request.Context()
	query := `
		SELECT
			m.id,
			m.user_id,
			u.username,
			u.email,
			COALESCE(r.role_name, 'user') as role,
			m.venue_id,
			v.name as venue_name,
			m.is_active,
			TO_CHAR(m.created_at, 'YYYY-MM-DD') as created_at
		FROM user_venue_mapping m
		JOIN users u ON u.id = m.user_id
		JOIN venues v ON v.id = m.venue_id
		LEFT JOIN user_roles ur ON ur.user_id = u.id
		LEFT JOIN roles r ON r.id = ur.role_id
		ORDER BY m.id DESC
	`
	rows, err := dal.Query(ctx, query)
	if err != nil {
		log.Printf("GetVenueMappings error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Database error"})
		return
	}
	defer rows.Close()

	var mappings []gin.H
	for rows.Next() {
		var id, userId, venueId int
		var username, email, role, venueName, createdAt string
		var isActive bool
		if err := rows.Scan(&id, &userId, &username, &email, &role, &venueId, &venueName, &isActive, &createdAt); err != nil {
			continue
		}
		mappings = append(mappings, gin.H{
			"id":         id,
			"user_id":    userId,
			"username":   username,
			"email":      email,
			"role":       role,
			"venue_id":   venueId,
			"venue_name": venueName,
			"is_active":  isActive,
			"created_at": createdAt,
		})
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "data": mappings})
}

type AddVenueMappingRequest struct {
	UserID  int `json:"user_id"`
	VenueID int `json:"venue_id"`
}

func AddVenueMapping(c *gin.Context) {
	var req AddVenueMappingRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid Request"})
		return
	}

	ctx := c.Request.Context()

	// Check if mapping already exists
	var count int
	dal.DB.QueryRow(ctx, "SELECT COUNT(*) FROM user_venue_mapping WHERE user_id=$1 AND venue_id=$2", req.UserID, req.VenueID).Scan(&count)
	if count > 0 {
		// Reactivate if inactive
		dal.ExecNonQuery(ctx, "UPDATE user_venue_mapping SET is_active=true WHERE user_id=$1 AND venue_id=$2", req.UserID, req.VenueID)
		c.JSON(http.StatusOK, gin.H{"success": true, "message": "Mapping reactivated"})
		return
	}

	_, err := dal.ExecNonQuery(ctx,
		"INSERT INTO user_venue_mapping (user_id, venue_id, is_active) VALUES ($1, $2, true)",
		req.UserID, req.VenueID)
	if err != nil {
		log.Printf("AddVenueMapping error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Failed to add mapping"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "message": "Venue mapped to user"})
}

type RemoveVenueMappingRequest struct {
	ID int `json:"id"`
}

func RemoveVenueMapping(c *gin.Context) {
	var req RemoveVenueMappingRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid Request"})
		return
	}
	_, err := dal.ExecNonQuery(c.Request.Context(), "DELETE FROM user_venue_mapping WHERE id=$1", req.ID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Failed to remove mapping"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "message": "Mapping removed"})
}

func GetVenueListForMapping(c *gin.Context) {
	ctx := c.Request.Context()
	rows, err := dal.Query(ctx, "SELECT id, name, COALESCE(location,'') FROM venues WHERE is_active=true ORDER BY name")
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Database error"})
		return
	}
	defer rows.Close()
	var venues []gin.H
	for rows.Next() {
		var id int
		var name, location string
		if err := rows.Scan(&id, &name, &location); err != nil {
			continue
		}
		venues = append(venues, gin.H{"id": id, "name": name, "location": location})
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "data": venues})
}

func GetUserListForMapping(c *gin.Context) {
	ctx := c.Request.Context()
	rows, err := dal.Query(ctx, `
		SELECT u.id, u.username, u.email, COALESCE(r.role_name,'user') as role
		FROM users u
		LEFT JOIN user_roles ur ON ur.user_id = u.id
		LEFT JOIN roles r ON r.id = ur.role_id
		WHERE u.is_active = true
		ORDER BY u.username
	`)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Database error"})
		return
	}
	defer rows.Close()
	var users []gin.H
	for rows.Next() {
		var id int
		var username, email, role string
		if err := rows.Scan(&id, &username, &email, &role); err != nil {
			continue
		}
		users = append(users, gin.H{"id": id, "username": username, "email": email, "role": role})
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "data": users})
}
