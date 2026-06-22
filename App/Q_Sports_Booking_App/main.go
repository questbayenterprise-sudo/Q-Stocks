package main

import (
	"fmt"
	"log"
	"net/http"
	"os" // Added to get Environment Variables
	"strings"

	"github.com/gin-gonic/gin"
	_ "github.com/lib/pq"

	bal "github.com/qsports/q-stocks-app/bal"
	dal "github.com/qsports/q-stocks-app/dal"
)

func main() {
	// 1. Initialize Database - In Render, use Environment Variable for DSN
	err := dal.ConnectPostgres()
	if err != nil {
		log.Fatal("❌ Database connection failed: ", err)
	}
	fmt.Println("✅ Successfully connected to database")

	// Set Gin to Release Mode when on Render
	if os.Getenv("RENDER") == "true" {
		gin.SetMode(gin.ReleaseMode)
	}

	router := gin.Default()

	// 2. Universal Middleware
	router.Use(func(c *gin.Context) {
		origin := c.Request.Header.Get("Origin")
		// Allow Local Dev and your future Production Domain
		if origin == "http://localhost:5173" || origin == "" {
			c.Writer.Header().Set("Access-Control-Allow-Origin", origin)
		}
		c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, accept, origin, Cache-Control, X-Requested-With")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT, DELETE")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}
		c.Next()
	})

	// 3. Serve Physical Uploads
	router.Static("/uploads", "./uploads")

	// 4. API Routes
	api := router.Group("/api")
	{
		api.POST("/SignIn", bal.SignIn)
		api.POST("/Verify_OTP", bal.Verify_OTP)
		api.POST("/Get_UserProfile", bal.Get_UserProfile)
		api.POST("/Update_Cususer", bal.Update_Cususer)
		api.POST("/GetShopAnalytics", bal.GetShopAnalytics)
		api.POST("/GetRecentSales", bal.GetRecentSales)
		api.POST("/Shop_overall_list", bal.Shop_overall_list)
		api.POST("/SaveShop", bal.SaveShop)
		api.POST("/ProcessSale", bal.ProcessSale)
		api.GET("/GetIncomeHistory", bal.GetIncomeHistory)
		api.POST("/SaveIncome", bal.SaveIncome)
		api.GET("/GetStocks", bal.GetStocks)
		api.POST("/UpdateStock", bal.UpdateStock)
		api.POST("/DeleteShop", bal.DeleteShop)
		api.POST("/GetProducts", bal.GetProducts)
		api.POST("/SaveProduct", bal.SaveProduct)
		api.POST("/DeleteProduct", bal.DeleteProduct)
		api.GET("/GetAllCustomers", bal.GetAllCustomers)
		api.POST("/CreateCustomer", bal.CreateCustomer)
		api.POST("/GetCustomerLedger", bal.GetCustomerLedger)

		api.GET("/status", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{"status": "ok", "app": "q-stocks-app"})
		})
	}

	// 5. Serve React Static Files
	// On Render, we use a relative path from the root directory
	distPath := "../../Web/dist"

	router.Static("/assets", distPath+"/assets")
	router.StaticFile("/favicon.ico", distPath+"/favicon.ico")
	router.StaticFile("/logo.png", distPath+"/logo.png")
	router.StaticFile("/", distPath+"/index.html")

	// 6. SPA Handler (The Logic Fix)
	router.NoRoute(func(c *gin.Context) {
		path := c.Request.URL.Path
		if strings.HasPrefix(path, "/api") || strings.HasPrefix(path, "/uploads") {
			c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "Resource not found"})
			return
		}
		c.File(distPath + "/index.html")
	})

	// 7. Dynamic Port for Render
	port := os.Getenv("PORT")
	if port == "" {
		port = "5000" // Default for local
	}

	fmt.Printf("🚀 Server running on port %s\n", port)
	// Render requires 0.0.0.0 for the host
	if err := router.Run("0.0.0.0:" + port); err != nil {
		log.Fatalf("❌ Server failed: %v", err)
	}
}
