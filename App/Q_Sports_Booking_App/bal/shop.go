package bal

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	dal "github.com/qsports/q-stocks-app/dal"
)

// ShopSearchRequest defines the structure for the incoming JSON body
type ShopSearchRequest struct {
	UserID   string `json:"user_id"`
	UserType string `json:"user_type"`
	Search   string `json:"search"`
}

// Shop_overall_list handles fetching shops based on roles (Admin vs Manager)
func Shop_overall_list(c *gin.Context) {
	var req ShopSearchRequest
	ctx := c.Request.Context()

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid request parameters"})
		return
	}

	var query string
	var args []interface{}
	userType := strings.ToLower(req.UserType)
	searchTerm := "%" + strings.TrimSpace(req.Search) + "%"

	if userType == "admin" {
		query = `
			SELECT id, name, location, COALESCE(description, '') as description, COALESCE(image_url, '') as image_url 
			FROM shops 
			WHERE is_active = true AND (name ILIKE $1 OR location ILIKE $1)
			ORDER BY id DESC`
		args = append(args, searchTerm)
	} else {
		query = `
			SELECT s.id, s.name, s.location, COALESCE(s.description, '') as description, COALESCE(s.image_url, '') as image_url
			FROM shops s
			INNER JOIN shop_user_mapping m ON m.shop_id = s.id
			WHERE m.user_id = $1 AND s.is_active = true AND m.is_active = true 
			AND (s.name ILIKE $2 OR s.location ILIKE $2)
			ORDER BY s.id DESC`
		args = append(args, req.UserID, searchTerm)
	}

	rows, err := dal.DB.Query(ctx, query, args...)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Database error"})
		return
	}
	defer rows.Close()

	shops := []gin.H{}
	for rows.Next() {
		var id int
		var name, loc, desc, img string
		if err := rows.Scan(&id, &name, &loc, &desc, &img); err == nil {
			shops = append(shops, gin.H{
				"id":          id,
				"name":        name,
				"location":    loc,
				"description": desc,
				"image_url":   img,
			})
		}
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "rows": shops})
}

// SaveShop handles both Creating and Updating a shop branch
func SaveShop(c *gin.Context) {
	ctx := c.Request.Context()

	idStr := c.PostForm("id") // "0" for new, numeric string for update
	name := c.PostForm("name")
	location := c.PostForm("location")
	description := c.PostForm("description")
	userId := c.PostForm("userid")

	// Handle Image Upload
	file, err := c.FormFile("image")
	var imagePath string
	if err == nil {
		uploadDir := "uploads/shops"
		os.MkdirAll(uploadDir, 0755)
		filename := fmt.Sprintf("%d_%s", time.Now().Unix(), filepath.Base(file.Filename))
		imagePath = filepath.Join(uploadDir, filename)
		c.SaveUploadedFile(file, imagePath)
	} else {
		imagePath = c.PostForm("existing_image")
	}

	tx, err := dal.DB.Begin(ctx)
	if err != nil {
		c.JSON(500, gin.H{"success": false, "message": "Internal Server Error"})
		return
	}
	defer tx.Rollback(ctx)

	var lastID int
	if idStr == "" || idStr == "0" {
		// INSERT NEW SHOP
		query := `INSERT INTO shops (name, location, description, image_url, created_by) 
				  VALUES ($1, $2, $3, $4, $5) RETURNING id`
		err = tx.QueryRow(ctx, query, name, location, description, imagePath, userId).Scan(&lastID)
		if err == nil {
			// Auto map creator to shop
			tx.Exec(ctx, `INSERT INTO shop_user_mapping (user_id, shop_id, is_active) VALUES ($1, $2, true)`, userId, lastID)
		}
	} else {
		// UPDATE EXISTING SHOP
		id, _ := strconv.Atoi(idStr)
		lastID = id
		query := `UPDATE shops SET name=$1, location=$2, description=$3, image_url=$4, updated_at=NOW() WHERE id=$5`
		_, err = tx.Exec(ctx, query, name, location, description, imagePath, id)
	}

	if err != nil {
		log.Printf("SaveShop Error: %v", err)
		c.JSON(500, gin.H{"success": false, "message": "Failed to save shop"})
		return
	}

	tx.Commit(ctx)
	c.JSON(http.StatusOK, gin.H{"success": true, "message": "Shop saved successfully", "id": lastID})
}

// DeleteShop handles deactivating a branch (Soft Delete)
func DeleteShop(c *gin.Context) {
	ctx := c.Request.Context()
	var req struct {
		ID string `json:"id" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "ID is required"})
		return
	}

	query := `UPDATE shops SET is_active = false, updated_at = NOW() WHERE id = $1`
	res, err := dal.DB.Exec(ctx, query, req.ID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Database error"})
		return
	}

	if res.RowsAffected() == 0 {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "Shop not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"success": true, "message": "Shop deactivated successfully"})
}