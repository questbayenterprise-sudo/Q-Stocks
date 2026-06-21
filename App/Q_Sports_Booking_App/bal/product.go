package bal

import (
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	dal "github.com/qsports/q-stocks-app/dal"
)

// GetProducts handles fetching the catalog
func GetProducts(c *gin.Context) {
	ctx := c.Request.Context()

	// Use COALESCE to prevent scanning NULL into string errors
	query := `
		SELECT id, name, category_id, uom, base_price, COALESCE(image_url, '') 
		FROM products 
		WHERE is_active = true 
		ORDER BY name ASC`

	rows, err := dal.DB.Query(ctx, query)
	if err != nil {
		c.JSON(500, gin.H{"success": false, "message": "Database error"})
		return
	}
	defer rows.Close()

	products := []gin.H{}
	for rows.Next() {
		var id, catId int
		var name, uom, img string
		var price float64
		if err := rows.Scan(&id, &name, &catId, &uom, &price, &img); err == nil {
			products = append(products, gin.H{
				"id":          id,
				"name":        name,
				"category_id": catId,
				"uom":         uom,
				"base_price":  price,
				"image_url":   img,
			})
		}
	}
	c.JSON(200, gin.H{"success": true, "data": products})
}

// SaveProduct handles both Insert and Update
func SaveProduct(c *gin.Context) {
	ctx := c.Request.Context()

	idStr := c.PostForm("id") // "0" for new
	name := c.PostForm("name")
	catId := c.PostForm("category_id")
	uom := c.PostForm("uom")
	price, _ := strconv.ParseFloat(c.PostForm("base_price"), 64)

	// Handle Image Upload
	file, err := c.FormFile("image")
	var imagePath string
	if err == nil {
		uploadDir := "uploads/products"
		os.MkdirAll(uploadDir, 0755)
		filename := fmt.Sprintf("%d_%s", time.Now().Unix(), file.Filename)
		imagePath = filepath.Join(uploadDir, filename)
		c.SaveUploadedFile(file, imagePath)
	} else {
		imagePath = c.PostForm("existing_image")
	}

	if idStr == "" || idStr == "0" {
		// INSERT
		query := `INSERT INTO products (name, category_id, uom, base_price, image_url) VALUES ($1, $2, $3, $4, $5)`
		_, err = dal.DB.Exec(ctx, query, name, catId, uom, price, imagePath)
	} else {
		// UPDATE
		query := `UPDATE products SET name=$1, category_id=$2, uom=$3, base_price=$4, image_url=$5 WHERE id=$6`
		_, err = dal.DB.Exec(ctx, query, name, catId, uom, price, imagePath, idStr)
	}

	if err != nil {
		c.JSON(500, gin.H{"success": false, "message": "Failed to save product"})
		return
	}
	c.JSON(200, gin.H{"success": true, "message": "Product saved successfully"})
}

// DeleteProduct (Soft Delete)
func DeleteProduct(c *gin.Context) {
	var req struct {
		ID string `json:"id" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"success": false, "message": "ID is required"})
		return
	}

	query := `UPDATE products SET is_active = false WHERE id = $1`
	_, err := dal.DB.Exec(c.Request.Context(), query, req.ID)
	if err != nil {
		c.JSON(500, gin.H{"success": false, "message": "Delete failed"})
		return
	}
	c.JSON(200, gin.H{"success": true})
}
