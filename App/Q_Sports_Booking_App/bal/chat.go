package bal

import (
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	dal "github.com/qsports/q-sports-booking-app/dal"
)

// ── Request / Response structs ──

type CreateConversationRequest struct {
	User1ID   int    `json:"user1_id" binding:"required"`
	User2ID   int    `json:"user2_id" binding:"required"`
	VenueID   *int   `json:"venue_id"`
	BookingID *int   `json:"booking_id"`
	Context   string `json:"context"` // general, booking, support
}

type GetConversationsRequest struct {
	UserID string `json:"user_id" binding:"required"`
}

type SendMessageRequest struct {
	ConversationID int    `json:"conversation_id" binding:"required"`
	SenderID       int    `json:"sender_id" binding:"required"`
	Message        string `json:"message" binding:"required"`
	MessageType    string `json:"message_type"` // text, image, file
}

type GetMessagesRequest struct {
	ConversationID string `json:"conversation_id" binding:"required"`
	Page           int    `json:"page"`
	PageSize       int    `json:"page_size"`
}

type ConversationResponse struct {
	ID            int    `json:"id"`
	OtherUserID   int    `json:"other_user_id"`
	OtherUserName string `json:"other_user_name"`
	VenueName     string `json:"venue_name"`
	Context       string `json:"context"`
	LastMessage   string `json:"last_message"`
	LastMessageAt string `json:"last_message_at"`
	UnreadCount   int    `json:"unread_count"`
}

type MessageResponse struct {
	ID             int    `json:"id"`
	ConversationID int    `json:"conversation_id"`
	SenderID       int    `json:"sender_id"`
	SenderName     string `json:"sender_name"`
	Message        string `json:"message"`
	MessageType    string `json:"message_type"`
	IsRead         bool   `json:"is_read"`
	CreatedAt      string `json:"created_at"`
}

// ── Create or Get Conversation ──

func CreateConversation(c *gin.Context) {
	var req CreateConversationRequest
	ctx := c.Request.Context()

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid request"})
		return
	}

	if req.Context == "" {
		req.Context = "general"
	}

	// Normalize: always store smaller ID as user1
	u1, u2 := req.User1ID, req.User2ID
	if u1 > u2 {
		u1, u2 = u2, u1
	}

	venueID := 0
	if req.VenueID != nil {
		venueID = *req.VenueID
	}
	bookingID := 0
	if req.BookingID != nil {
		bookingID = *req.BookingID
	}

	// Check if conversation already exists
	var existingID int
	checkQuery := `
		SELECT id FROM conversations
		WHERE user1_id = $1 AND user2_id = $2
		  AND COALESCE(venue_id, 0) = $3
		  AND COALESCE(booking_id, 0) = $4
		LIMIT 1
	`
	err := dal.DB.QueryRow(ctx, checkQuery, u1, u2, venueID, bookingID).Scan(&existingID)
	if err == nil {
		// Conversation exists
		c.JSON(http.StatusOK, gin.H{
			"success":         true,
			"conversation_id": existingID,
			"message":         "Conversation already exists",
		})
		return
	}

	// Create new conversation
	insertQuery := `
		INSERT INTO conversations (user1_id, user2_id, venue_id, booking_id, context)
		VALUES ($1, $2, NULLIF($3, 0), NULLIF($4, 0), $5)
		RETURNING id
	`
	var newID int
	err = dal.DB.QueryRow(ctx, insertQuery, u1, u2, venueID, bookingID, req.Context).Scan(&newID)
	if err != nil {
		log.Printf("[CHAT] Create conversation error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Failed to create conversation"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success":         true,
		"conversation_id": newID,
		"message":         "Conversation created",
	})
}

// ── Get Conversations for a User ──

func GetConversations(c *gin.Context) {
	var req GetConversationsRequest
	ctx := c.Request.Context()

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid request"})
		return
	}

	query := `
		SELECT
			c.id,
			CASE WHEN c.user1_id = $1 THEN c.user2_id ELSE c.user1_id END as other_user_id,
			CASE WHEN c.user1_id = $1 THEN u2.username ELSE u1.username END as other_user_name,
			COALESCE(v.name, '') as venue_name,
			c.context,
			COALESCE(
				(SELECT m.message FROM messages m WHERE m.conversation_id = c.id ORDER BY m.created_at DESC LIMIT 1),
				''
			) as last_message,
			COALESCE(
				(SELECT TO_CHAR(m.created_at, 'YYYY-MM-DD HH24:MI') FROM messages m WHERE m.conversation_id = c.id ORDER BY m.created_at DESC LIMIT 1),
				''
			) as last_message_at,
			COALESCE(
				(SELECT COUNT(*) FROM messages m WHERE m.conversation_id = c.id AND m.sender_id != $1 AND m.is_read = FALSE),
				0
			)::int as unread_count
		FROM conversations c
		JOIN users u1 ON c.user1_id = u1.id
		JOIN users u2 ON c.user2_id = u2.id
		LEFT JOIN venues v ON c.venue_id = v.id
		WHERE (c.user1_id = $1 OR c.user2_id = $1) AND c.is_active = TRUE
		ORDER BY
			COALESCE(
				(SELECT m.created_at FROM messages m WHERE m.conversation_id = c.id ORDER BY m.created_at DESC LIMIT 1),
				c.created_at
			) DESC
	`

	rows, err := dal.Query(ctx, query, req.UserID)
	if err != nil {
		log.Printf("[CHAT] Get conversations error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Database error"})
		return
	}
	defer rows.Close()

	var conversations []ConversationResponse
	for rows.Next() {
		var conv ConversationResponse
		if err := rows.Scan(
			&conv.ID, &conv.OtherUserID, &conv.OtherUserName,
			&conv.VenueName, &conv.Context,
			&conv.LastMessage, &conv.LastMessageAt, &conv.UnreadCount,
		); err != nil {
			log.Printf("[CHAT] Scan error: %v", err)
			continue
		}
		conversations = append(conversations, conv)
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    conversations,
	})
}

// ── Send Message ──

func SendMessage(c *gin.Context) {
	var req SendMessageRequest
	ctx := c.Request.Context()

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid request"})
		return
	}

	if req.MessageType == "" {
		req.MessageType = "text"
	}

	// Verify sender is part of conversation
	var count int
	checkQuery := `
		SELECT COUNT(*) FROM conversations
		WHERE id = $1 AND (user1_id = $2 OR user2_id = $2) AND is_active = TRUE
	`
	err := dal.DB.QueryRow(ctx, checkQuery, req.ConversationID, req.SenderID).Scan(&count)
	if err != nil || count == 0 {
		c.JSON(http.StatusForbidden, gin.H{"success": false, "message": "Not authorized for this conversation"})
		return
	}

	// Insert message
	insertQuery := `
		INSERT INTO messages (conversation_id, sender_id, message, message_type)
		VALUES ($1, $2, $3, $4)
		RETURNING id, TO_CHAR(created_at, 'YYYY-MM-DD HH24:MI:SS')
	`
	var msgID int
	var createdAt string
	err = dal.DB.QueryRow(ctx, insertQuery,
		req.ConversationID, req.SenderID, req.Message, req.MessageType,
	).Scan(&msgID, &createdAt)
	if err != nil {
		log.Printf("[CHAT] Send message error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Failed to send message"})
		return
	}

	// Update conversation timestamp
	_, _ = dal.ExecNonQuery(ctx,
		`UPDATE conversations SET updated_at = NOW() WHERE id = $1`,
		req.ConversationID,
	)

	// Log notification (FCM for chat will be added when Firebase is configured)
	go func() {
		var receiverID int
		recvQuery := `
			SELECT CASE WHEN user1_id = $2 THEN user2_id ELSE user1_id END
			FROM conversations WHERE id = $1
		`
		if err := dal.DB.QueryRow(ctx, recvQuery, req.ConversationID, req.SenderID).Scan(&receiverID); err == nil {
			var senderName string
			_ = dal.DB.QueryRow(ctx, `SELECT username FROM users WHERE id = $1`, req.SenderID).Scan(&senderName)
			log.Printf("[CHAT] New message from %s (ID:%d) to user %d in conversation %d",
				senderName, req.SenderID, receiverID, req.ConversationID)
		}
	}()

	c.JSON(http.StatusOK, gin.H{
		"success":    true,
		"message_id": msgID,
		"created_at": createdAt,
	})
}

// ── Get Messages for a Conversation ──

func GetMessages(c *gin.Context) {
	var req GetMessagesRequest
	ctx := c.Request.Context()

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid request"})
		return
	}

	if req.Page <= 0 {
		req.Page = 1
	}
	if req.PageSize <= 0 {
		req.PageSize = 50
	}
	offset := (req.Page - 1) * req.PageSize

	query := `
		SELECT
			m.id,
			m.conversation_id,
			m.sender_id,
			u.username as sender_name,
			m.message,
			m.message_type,
			m.is_read,
			TO_CHAR(m.created_at, 'YYYY-MM-DD HH24:MI:SS') as created_at
		FROM messages m
		JOIN users u ON m.sender_id = u.id
		WHERE m.conversation_id = $1
		ORDER BY m.created_at ASC
		LIMIT $2 OFFSET $3
	`

	rows, err := dal.Query(ctx, query, req.ConversationID, req.PageSize, offset)
	if err != nil {
		log.Printf("[CHAT] Get messages error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Database error"})
		return
	}
	defer rows.Close()

	var messages []MessageResponse
	for rows.Next() {
		var msg MessageResponse
		if err := rows.Scan(
			&msg.ID, &msg.ConversationID, &msg.SenderID, &msg.SenderName,
			&msg.Message, &msg.MessageType, &msg.IsRead, &msg.CreatedAt,
		); err != nil {
			log.Printf("[CHAT] Scan error: %v", err)
			continue
		}
		messages = append(messages, msg)
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    messages,
	})
}

// ── Mark Messages as Read ──

func MarkMessagesRead(c *gin.Context) {
	ctx := c.Request.Context()

	var req struct {
		ConversationID int `json:"conversation_id" binding:"required"`
		UserID         int `json:"user_id" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid request"})
		return
	}

	// Mark all messages from the OTHER user as read
	updateQuery := `
		UPDATE messages
		SET is_read = TRUE
		WHERE conversation_id = $1 AND sender_id != $2 AND is_read = FALSE
	`
	_, err := dal.ExecNonQuery(ctx, updateQuery, req.ConversationID, req.UserID)
	if err != nil {
		log.Printf("[CHAT] Mark read error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Failed to update"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"success": true, "message": "Messages marked as read"})
}

// ── Get Unread Count for a User ──

func GetUnreadCount(c *gin.Context) {
	ctx := c.Request.Context()

	var req struct {
		UserID string `json:"user_id" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid request"})
		return
	}

	query := `
		SELECT COALESCE(SUM(
			(SELECT COUNT(*) FROM messages m
			 WHERE m.conversation_id = c.id AND m.sender_id != $1 AND m.is_read = FALSE)
		), 0)::int
		FROM conversations c
		WHERE (c.user1_id = $1 OR c.user2_id = $1) AND c.is_active = TRUE
	`

	var count int
	err := dal.DB.QueryRow(ctx, query, req.UserID).Scan(&count)
	if err != nil {
		c.JSON(http.StatusOK, gin.H{"success": true, "count": 0})
		return
	}

	c.JSON(http.StatusOK, gin.H{"success": true, "count": count})
}

// ── Get Contactable Users (for starting new chat) ──

func GetChatContacts(c *gin.Context) {
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
		// Admin can contact everyone
		query = `
			SELECT u.id, u.username, r.role_name as user_type
			FROM users u
			LEFT JOIN user_roles ur ON ur.user_id = u.id
			LEFT JOIN roles r ON r.id = ur.role_id
			WHERE u.id != $1 AND u.is_active = TRUE
			ORDER BY u.username
		`
	case "owner", "vendor", "manager":
		// Owner can contact admin + users who booked their venues
		query = `
			SELECT DISTINCT u.id, u.username, r.role_name as user_type
			FROM users u
			LEFT JOIN user_roles ur ON ur.user_id = u.id
			LEFT JOIN roles r ON r.id = ur.role_id
			WHERE u.id != $1 AND u.is_active = TRUE
			AND (
				r.role_name = 'admin'
				OR u.id IN (
					SELECT b.user_id FROM bookings b
					WHERE b.venue_id IN (
						SELECT venue_id FROM user_venue_mapping WHERE user_id = $1
					)
				)
			)
			ORDER BY u.username
		`
	default:
		// User can contact admin + venue owners of venues they booked
		query = `
			SELECT DISTINCT u.id, u.username, r.role_name as user_type
			FROM users u
			LEFT JOIN user_roles ur ON ur.user_id = u.id
			LEFT JOIN roles r ON r.id = ur.role_id
			WHERE u.id != $1 AND u.is_active = TRUE
			AND (
				r.role_name = 'admin'
				OR u.id IN (
					SELECT uvm.user_id FROM user_venue_mapping uvm
					WHERE uvm.venue_id IN (
						SELECT b.venue_id FROM bookings b WHERE b.user_id = $1
					)
				)
			)
			ORDER BY u.username
		`
	}

	rows, err := dal.Query(ctx, query, req.UserID)
	if err != nil {
		log.Printf("[CHAT] Get contacts error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Database error"})
		return
	}
	defer rows.Close()

	type Contact struct {
		ID       int    `json:"id"`
		Username string `json:"username"`
		UserType string `json:"user_type"`
	}

	var contacts []Contact
	for rows.Next() {
		var ct Contact
		if err := rows.Scan(&ct.ID, &ct.Username, &ct.UserType); err != nil {
			continue
		}
		contacts = append(contacts, ct)
	}

	c.JSON(http.StatusOK, gin.H{"success": true, "data": contacts})
}
