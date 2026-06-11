package bal

import (
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	dal "github.com/qsports/q-sports-booking-app/dal"
)

// ── Toggle Like (like/unlike) ──

func ToggleVenueLike(c *gin.Context) {
	ctx := c.Request.Context()

	var req struct {
		UserID  int `json:"user_id" binding:"required"`
		VenueID int `json:"venue_id" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid request"})
		return
	}

	// Check if already liked
	var exists bool
	err := dal.DB.QueryRow(ctx,
		`SELECT EXISTS(SELECT 1 FROM venue_likes WHERE user_id = $1 AND venue_id = $2)`,
		req.UserID, req.VenueID,
	).Scan(&exists)

	if err != nil {
		log.Printf("[LIKES] Check error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Database error"})
		return
	}

	if exists {
		// Unlike
		_, err = dal.ExecNonQuery(ctx,
			`DELETE FROM venue_likes WHERE user_id = $1 AND venue_id = $2`,
			req.UserID, req.VenueID,
		)
		if err != nil {
			log.Printf("[LIKES] Unlike error: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Failed to unlike"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"success": true, "liked": false, "message": "Venue unliked"})
	} else {
		// Like
		_, err = dal.ExecNonQuery(ctx,
			`INSERT INTO venue_likes (user_id, venue_id) VALUES ($1, $2)`,
			req.UserID, req.VenueID,
		)
		if err != nil {
			log.Printf("[LIKES] Like error: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Failed to like"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"success": true, "liked": true, "message": "Venue liked"})
	}
}

// ── Check if user liked a venue ──

func CheckVenueLike(c *gin.Context) {
	ctx := c.Request.Context()

	var req struct {
		UserID  int `json:"user_id" binding:"required"`
		VenueID int `json:"venue_id" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid request"})
		return
	}

	var liked bool
	err := dal.DB.QueryRow(ctx,
		`SELECT EXISTS(SELECT 1 FROM venue_likes WHERE user_id = $1 AND venue_id = $2)`,
		req.UserID, req.VenueID,
	).Scan(&liked)

	if err != nil {
		c.JSON(http.StatusOK, gin.H{"success": true, "liked": false})
		return
	}

	c.JSON(http.StatusOK, gin.H{"success": true, "liked": liked})
}

// ── Get like count for a venue ──

func GetVenueLikeCount(c *gin.Context) {
	ctx := c.Request.Context()

	var req struct {
		VenueID int `json:"venue_id" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid request"})
		return
	}

	var count int
	err := dal.DB.QueryRow(ctx,
		`SELECT COUNT(*) FROM venue_likes WHERE venue_id = $1`,
		req.VenueID,
	).Scan(&count)

	if err != nil {
		count = 0
	}

	c.JSON(http.StatusOK, gin.H{"success": true, "count": count})
}

// ── Get liked venues for a user (My Favorites page) ──

func GetLikedVenues(c *gin.Context) {
	ctx := c.Request.Context()

	var req struct {
		UserID   string `json:"user_id" binding:"required"`
		UserType string `json:"user_type"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid request"})
		return
	}

	var query string

	switch req.UserType {
	case "admin":
		// Admin: all liked venues with user info
		query = `
			SELECT
				vl.id,
				v.id as venue_id,
				v.name as venue_name,
				COALESCE(v.location, '') as location,
				COALESCE(v.image_url, '') as venue_image,
				v.price,
				u.id as user_id,
				u.username as user_name,
				TO_CHAR(vl.created_at, 'YYYY-MM-DD HH24:MI') as liked_at,
				(SELECT COUNT(*) FROM venue_likes vl2 WHERE vl2.venue_id = v.id) as total_likes
			FROM venue_likes vl
			JOIN venues v ON vl.venue_id = v.id
			JOIN users u ON vl.user_id = u.id
			ORDER BY vl.created_at DESC
		`
	case "owner", "vendor", "manager":
		// Owner: likes on their mapped venues
		query = `
			SELECT
				vl.id,
				v.id as venue_id,
				v.name as venue_name,
				COALESCE(v.location, '') as location,
				COALESCE(v.image_url, '') as venue_image,
				v.price,
				u.id as user_id,
				u.username as user_name,
				TO_CHAR(vl.created_at, 'YYYY-MM-DD HH24:MI') as liked_at,
				(SELECT COUNT(*) FROM venue_likes vl2 WHERE vl2.venue_id = v.id) as total_likes
			FROM venue_likes vl
			JOIN venues v ON vl.venue_id = v.id
			JOIN users u ON vl.user_id = u.id
			WHERE v.id IN (
				SELECT venue_id FROM user_venue_mapping WHERE user_id = ` + req.UserID + ` AND is_active = TRUE
			)
			ORDER BY vl.created_at DESC
		`
	default:
		// User: their own liked venues
		query = `
			SELECT
				vl.id,
				v.id as venue_id,
				v.name as venue_name,
				COALESCE(v.location, '') as location,
				COALESCE(v.image_url, '') as venue_image,
				v.price,
				` + req.UserID + ` as user_id,
				'' as user_name,
				TO_CHAR(vl.created_at, 'YYYY-MM-DD HH24:MI') as liked_at,
				(SELECT COUNT(*) FROM venue_likes vl2 WHERE vl2.venue_id = v.id) as total_likes
			FROM venue_likes vl
			JOIN venues v ON vl.venue_id = v.id
			WHERE vl.user_id = ` + req.UserID + `
			ORDER BY vl.created_at DESC
		`
	}

	rows, err := dal.Query(ctx, query)
	if err != nil {
		log.Printf("[LIKES] GetLikedVenues error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Database error"})
		return
	}
	defer rows.Close()

	type LikedVenue struct {
		ID         int     `json:"id"`
		VenueID    int     `json:"venue_id"`
		VenueName  string  `json:"venue_name"`
		Location   string  `json:"location"`
		VenueImage string  `json:"venue_image"`
		Price      float64 `json:"price"`
		UserID     int     `json:"user_id"`
		UserName   string  `json:"user_name"`
		LikedAt    string  `json:"liked_at"`
		TotalLikes int     `json:"total_likes"`
	}

	var results []LikedVenue
	for rows.Next() {
		var lv LikedVenue
		if err := rows.Scan(
			&lv.ID, &lv.VenueID, &lv.VenueName, &lv.Location,
			&lv.VenueImage, &lv.Price, &lv.UserID, &lv.UserName,
			&lv.LikedAt, &lv.TotalLikes,
		); err != nil {
			log.Printf("[LIKES] Scan error: %v", err)
			continue
		}
		results = append(results, lv)
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    results,
	})
}
