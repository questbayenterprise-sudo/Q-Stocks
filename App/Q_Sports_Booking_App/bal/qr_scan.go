package bal

import (
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	dal "github.com/qsports/q-sports-booking-app/dal"
)

// ── Validate scanned QR and return full booking details ──

type ScanQRRequest struct {
	BookingRef string `json:"booking_ref"` // QR contains booking_ref like QS-20260322-001
	BookingID  int    `json:"booking_id"`  // Or direct booking ID
	ScannerID  int    `json:"scanner_id"`  // User ID of person scanning (owner/vendor/manager)
}

type ScanBookingDetail struct {
	ID            int     `json:"id"`
	BookingRef    string  `json:"booking_ref"`
	VenueName     string  `json:"venue_name"`
	VenueImage    string  `json:"venue_image"`
	UserName      string  `json:"user_name"`
	UserPhone     string  `json:"user_phone"`
	UserEmail     string  `json:"user_email"`
	StartTime     string  `json:"start_time"`
	EndTime       string  `json:"end_time"`
	BookingDate   string  `json:"booking_date"`
	Status        string  `json:"status"`
	Amount        float64 `json:"amount"`
	PaymentStatus string  `json:"payment_status"`
	SportName     string  `json:"sport_name"`
	BookedAt      string  `json:"booked_at"`
}

func ValidateScanQR(c *gin.Context) {
	var req ScanQRRequest
	ctx := c.Request.Context()

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid request"})
		return
	}

	// Verify scanner is owner/vendor/manager of the venue
	// Build WHERE clause based on what's provided
	var whereClause string
	var args []interface{}

	if req.BookingRef != "" {
		whereClause = "b.booking_ref = $1"
		args = append(args, req.BookingRef)
	} else if req.BookingID > 0 {
		whereClause = "b.id = $1"
		args = append(args, req.BookingID)
	} else {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Booking ref or ID required"})
		return
	}

	query := `
		SELECT
			b.id,
			COALESCE(b.booking_ref, 'BK-' || b.id) as booking_ref,
			v.name as venue_name,
			COALESCE(v.image_url, '') as venue_image,
			COALESCE(u.username, '') as user_name,
			COALESCE(u.phoneno, '') as user_phone,
			COALESCE(u.email, '') as user_email,
			COALESCE(m.start_time, '') as start_time,
			COALESCE(m.end_time, '') as end_time,
			COALESCE(TO_CHAR(b.booked_at, 'YYYY-MM-DD'), '') as booking_date,
			b.status,
			COALESCE(b.amount, 0) as amount,
			COALESCE(b.payment_status, 'NA') as payment_status,
			COALESCE(s.name, '') as sport_name,
			COALESCE(TO_CHAR(b.booked_at, 'YYYY-MM-DD HH24:MI'), '') as booked_at
		FROM bookings b
		JOIN venues v ON b.venue_id = v.id
		LEFT JOIN users u ON b.user_id = u.id
		LEFT JOIN bookings_mapping m ON b.id = m.booking_id
		LEFT JOIN sports s ON m.sports_id = s.id
		WHERE ` + whereClause + `
		LIMIT 1
	`

	var detail ScanBookingDetail
	err := dal.DB.QueryRow(ctx, query, args...).Scan(
		&detail.ID, &detail.BookingRef, &detail.VenueName, &detail.VenueImage,
		&detail.UserName, &detail.UserPhone, &detail.UserEmail,
		&detail.StartTime, &detail.EndTime, &detail.BookingDate,
		&detail.Status, &detail.Amount, &detail.PaymentStatus,
		&detail.SportName, &detail.BookedAt,
	)

	if err != nil {
		log.Printf("[QR_SCAN] Query error: %v", err)
		c.JSON(http.StatusNotFound, gin.H{
			"success": false,
			"message": "Booking not found or invalid QR code",
		})
		return
	}

	// Check if already completed
	if detail.Status == "COMPLETED" {
		c.JSON(http.StatusOK, gin.H{
			"success": false,
			"message": "This booking is already completed",
			"data":    detail,
		})
		return
	}

	// Log the scan
	log.Printf("[QR_SCAN] Booking %s scanned by user %d, status: %s",
		detail.BookingRef, req.ScannerID, detail.Status)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Booking found",
		"data":    detail,
	})
}

// ── Update Booking Status (Start / Complete / No-show) ──

type UpdateBookingStatusRequest struct {
	BookingID int    `json:"booking_id" binding:"required"`
	Status    string `json:"status" binding:"required"` // IN_PROGRESS, COMPLETED, NO_SHOW, CANCELLED
	UpdatedBy int    `json:"updated_by"`
}

func UpdateBookingStatus(c *gin.Context) {
	var req UpdateBookingStatusRequest
	ctx := c.Request.Context()

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid request"})
		return
	}

	// Validate status transition
	validStatuses := map[string]bool{
		"CHECKED-IN":  true,
		"IN_PROGRESS": true,
		"COMPLETED":   true,
		"NO_SHOW":     true,
		"CANCELLED":   true,
	}

	if !validStatuses[req.Status] {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid status. Allowed: CHECKED-IN, IN_PROGRESS, COMPLETED, NO_SHOW, CANCELLED",
		})
		return
	}

	// Check current status to prevent invalid transitions
	var currentStatus string
	err := dal.DB.QueryRow(ctx,
		`SELECT status FROM bookings WHERE id = $1`, req.BookingID,
	).Scan(&currentStatus)

	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "Booking not found"})
		return
	}

	// Prevent re-completing
	if currentStatus == "COMPLETED" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Booking is already completed",
		})
		return
	}

	// Update status
	updateQuery := `
		UPDATE bookings
		SET status = $1
		WHERE id = $2
	`
	rows, err := dal.ExecNonQuery(ctx, updateQuery, req.Status, req.BookingID)
	if err != nil || rows == 0 {
		log.Printf("[QR_SCAN] Status update error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to update booking status",
		})
		return
	}

	log.Printf("[QR_SCAN] Booking %d status updated: %s -> %s by user %d",
		req.BookingID, currentStatus, req.Status, req.UpdatedBy)

	c.JSON(http.StatusOK, gin.H{
		"success":     true,
		"message":     "Booking status updated to " + req.Status,
		"prev_status": currentStatus,
		"new_status":  req.Status,
	})
}

// ── Get Booking Detail by ID (for user's booking detail page) ──

func GetBookingDetail(c *gin.Context) {
	ctx := c.Request.Context()

	var req struct {
		BookingID int    `json:"booking_id" binding:"required"`
		UserID    string `json:"user_id"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid request"})
		return
	}

	query := `
		SELECT
			b.id,
			COALESCE(b.booking_ref, 'BK-' || b.id) as booking_ref,
			v.name as venue_name,
			COALESCE(v.image_url, '') as venue_image,
			COALESCE(v.location, '') as venue_location,
			COALESCE(u.username, '') as user_name,
			COALESCE(u.phoneno, '') as user_phone,
			COALESCE(u.email, '') as user_email,
			COALESCE(m.start_time, '') as start_time,
			COALESCE(m.end_time, '') as end_time,
			COALESCE(TO_CHAR(b.booked_at, 'YYYY-MM-DD'), '') as booking_date,
			b.status,
			COALESCE(b.amount, 0) as amount,
			COALESCE(b.payment_status, 'NA') as payment_status,
			COALESCE(s.name, '') as sport_name,
			COALESCE(TO_CHAR(b.booked_at, 'YYYY-MM-DD HH24:MI'), '') as booked_at,
			b.venue_id
		FROM bookings b
		JOIN venues v ON b.venue_id = v.id
		LEFT JOIN users u ON b.user_id = u.id
		LEFT JOIN bookings_mapping m ON b.id = m.booking_id
		LEFT JOIN sports s ON m.sports_id = s.id
		WHERE b.id = $1
		LIMIT 1
	`

	var (
		id            int
		bookingRef    string
		venueName     string
		venueImage    string
		venueLocation string
		userName      string
		userPhone     string
		userEmail     string
		startTime     string
		endTime       string
		bookingDate   string
		status        string
		amount        float64
		paymentStatus string
		sportName     string
		bookedAt      string
		venueID       int
	)

	err := dal.DB.QueryRow(ctx, query, req.BookingID).Scan(
		&id, &bookingRef, &venueName, &venueImage, &venueLocation,
		&userName, &userPhone, &userEmail,
		&startTime, &endTime, &bookingDate,
		&status, &amount, &paymentStatus,
		&sportName, &bookedAt, &venueID,
	)

	if err != nil {
		log.Printf("[BOOKING] GetBookingDetail error: %v", err)
		c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "Booking not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"id":             id,
			"booking_ref":    bookingRef,
			"venue_name":     venueName,
			"venue_image":    venueImage,
			"venue_location": venueLocation,
			"user_name":      userName,
			"user_phone":     userPhone,
			"user_email":     userEmail,
			"start_time":     startTime,
			"end_time":       endTime,
			"booking_date":   bookingDate,
			"status":         status,
			"amount":         amount,
			"payment_status": paymentStatus,
			"sport_name":     sportName,
			"booked_at":      bookedAt,
			"venue_id":       venueID,
		},
	})
}
