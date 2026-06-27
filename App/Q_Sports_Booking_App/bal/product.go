package bal

import (
	"fmt"
	"log"
	"net/http"
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

	query := `
		SELECT id, name, category_id, uom, base_price, COALESCE(image_url, '') 
		FROM products 
		WHERE is_active = true 
		ORDER BY name ASC`

	rows, err := dal.DB.Query(ctx, query)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Database error"})
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
	c.JSON(http.StatusOK, gin.H{"success": true, "data": products})
}

// SaveProduct handles both Insert and Update with sequential image naming
func SaveProduct(c *gin.Context) {
	ctx := c.Request.Context()

	idStr := c.PostForm("id")
	name := c.PostForm("name")
	catId := c.PostForm("category_id")
	uom := c.PostForm("uom")
	price, _ := strconv.ParseFloat(c.PostForm("base_price"), 64)

	file, fileErr := c.FormFile("image")

	// Start Transaction
	tx, err := dal.DB.Begin(ctx)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "DB Transaction Error"})
		return
	}
	defer tx.Rollback(ctx)

	var productID int
	isNew := idStr == "" || idStr == "0"

	// 1. Initial Database Operation
	if isNew {
		query := `INSERT INTO products (name, category_id, uom, base_price, is_active) 
				  VALUES ($1, $2, $3, $4, true) RETURNING id`
		err = tx.QueryRow(ctx, query, name, catId, uom, price).Scan(&productID)
	} else {
		productID, _ = strconv.Atoi(idStr)
		query := `UPDATE products SET name=$1, category_id=$2, uom=$3, base_price=$4, updated_at=NOW() WHERE id=$5`
		_, err = tx.Exec(ctx, query, name, catId, uom, price, productID)
	}

	if err != nil {
		log.Printf("❌ SaveProduct DB Error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Failed to save product details"})
		return
	}

	// 2. Handle Image Processing with Sequence Naming
	if fileErr == nil {
		uploadDir := "uploads/products"
		os.MkdirAll(uploadDir, 0755)

		// NAMING CONVENTION: prod_ID_TIMESTAMP.ext (e.g. prod_5_1719000000.jpg)
		extension := filepath.Ext(file.Filename)
		timestamp := time.Now().Unix()
		newFileName := fmt.Sprintf("prod_%d_%d%s", productID, timestamp, extension)
		imagePath := filepath.Join(uploadDir, newFileName)

		// Convert backslashes to forward slashes for web compatibility
		imageWebPath := filepath.ToSlash(imagePath)

		if err := c.SaveUploadedFile(file, imagePath); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Failed to save image file"})
			return
		}

		// Update the database record with the new sequential path
		_, err = tx.Exec(ctx, `UPDATE products SET image_url = $1 WHERE id = $2`, imageWebPath, productID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Failed to update image path"})
			return
		}
	} else {
		// If no new image, but updating, keep the old one if passed
		existingImg := c.PostForm("existing_image")
		if existingImg != "" && !isNew {
			_, _ = tx.Exec(ctx, `UPDATE products SET image_url = $1 WHERE id = $2`, existingImg, productID)
		}
	}

	// 3. Final Commit
	if err := tx.Commit(ctx); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Transaction commit failed"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Product catalog updated",
		"id":      productID,
	})
}
func DeleteProduct(c *gin.Context) {
	// 1. Define request struct with flexible type
	var req struct {
		ID interface{} `json:"id" binding:"required"`
	}

	// 2. Bind JSON
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "ID is required"})
		return
	}

	// 3. Convert ID to Integer (using the helper we created earlier)
	productID := AnyToInt(req.ID)

	// 4. Execute Update
	query := `UPDATE products SET is_active = false, updated_at = NOW() WHERE id = $1`
	res, err := dal.DB.Exec(c.Request.Context(), query, productID)

	if err != nil {
		// THIS LOG WILL SHOW YOU THE REAL ERROR IN THE TERMINAL
		log.Printf("❌ DeleteProduct SQL Error: %v", err)

		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Database error: " + err.Error(),
		})
		return
	}

	// 5. Check if the product existed
	if res.RowsAffected() == 0 {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "Product not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"success": true})
}
