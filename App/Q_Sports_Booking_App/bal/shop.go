package bal

import (
	"fmt"
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

func SaveShop(c *gin.Context) {
	ctx := c.Request.Context()

	idStr := c.PostForm("id")
	name := c.PostForm("name")
	location := c.PostForm("location")
	description := c.PostForm("description")
	userId := c.PostForm("userid")

	file, fileErr := c.FormFile("image")

	tx, err := dal.DB.Begin(ctx)
	if err != nil {
		c.JSON(500, gin.H{"success": false, "message": "DB Transaction Error"})
		return
	}
	defer tx.Rollback(ctx)

	var lastID int
	isNew := idStr == "" || idStr == "0"

	// 1. Initial DB Operation
	if isNew {
		query := `INSERT INTO shops (name, location, description, created_by) 
				  VALUES ($1, $2, $3, $4) RETURNING id`
		err = tx.QueryRow(ctx, query, name, location, description, userId).Scan(&lastID)
		if err == nil {
			tx.Exec(ctx, `INSERT INTO shop_user_mapping (user_id, shop_id, is_active) VALUES ($1, $2, true)`, userId, lastID)
		}
	} else {
		lastID, _ = strconv.Atoi(idStr)
		query := `UPDATE shops SET name=$1, location=$2, description=$3, updated_at=NOW() WHERE id=$4`
		_, err = tx.Exec(ctx, query, name, location, description, lastID)
	}

	if err != nil {
		c.JSON(500, gin.H{"success": false, "message": err.Error()})
		return
	}

	// 2. Handle Image Processing with Sequence Naming
	if fileErr == nil {
		uploadDir := "uploads/shops"
		os.MkdirAll(uploadDir, 0755)

		// SUGGESTED FILENAME: shop_1_1719000000.jpg
		extension := filepath.Ext(file.Filename)
		timestamp := time.Now().Unix()
		newFileName := fmt.Sprintf("shop_%d_%d%s", lastID, timestamp, extension)
		imagePath := filepath.Join(uploadDir, newFileName)

		// Convert to web-friendly path (forward slashes)
		imageWebPath := filepath.ToSlash(imagePath)

		if err := c.SaveUploadedFile(file, imagePath); err != nil {
			c.JSON(500, gin.H{"success": false, "message": "Failed to save image file"})
			return
		}

		// Update the database with the final sequenced path
		_, err = tx.Exec(ctx, `UPDATE shops SET image_url = $1 WHERE id = $2`, imageWebPath, lastID)
		if err != nil {
			c.JSON(500, gin.H{"success": false, "message": "Failed to update image path in DB"})
			return
		}
	}

	// 3. Final Commit
	if err := tx.Commit(ctx); err != nil {
		c.JSON(500, gin.H{"success": false, "message": "Transaction Commit Failed"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Shop saved successfully",
		"id":      lastID,
	})
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
