package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	_ "github.com/lib/pq"

	bal "github.com/qsports/q-stocks-app/bal"
	dal "github.com/qsports/q-stocks-app/dal"
)

func main() {
	// 1. Initialize Database
	// dal.ConnectPostgres should use os.Getenv("DATABASE_URL") for Render
	err := dal.ConnectPostgres()
	if err != nil {
		log.Fatal("❌ Database connection failed: ", err)
	}
	fmt.Println("✅ Successfully connected to database")

	// Set Gin to Release Mode when running on Render for better performance
	if os.Getenv("RENDER") == "true" {
		gin.SetMode(gin.ReleaseMode)
	}

	router := gin.Default()

	// 2. Universal Middleware (CORS & Security)
	router.Use(func(c *gin.Context) {
		origin := c.Request.Header.Get("Origin")
		// Allow local React dev server and same-origin production requests
		if origin == "http://localhost:5173" || origin == "" {
			c.Writer.Header().Set("Access-Control-Allow-Origin", origin)
		} else {
			// In production on Render, allow all or specific domain
			c.Writer.Header().Set("Access-Control-Allow-Origin", origin)
		}

		c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, accept, origin, Cache-Control, X-Requested-With")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT, DELETE")

		// Handle Preflight (OPTIONS)
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}

		c.Next()
	})

	// 3. Ensure Upload Directories Exist and Serve them
	os.MkdirAll("./uploads/shops", 0755)
	os.MkdirAll("./uploads/products", 0755)
	router.Static("/uploads", "./uploads")

	// 4. API Routes Group (Shared by Web and Mobile)
	api := router.Group("/api")
	{
		// Auth & User
		api.POST("/SignIn", bal.SignIn)
		api.POST("/Verify_OTP", bal.Verify_OTP)
		api.POST("/Get_UserProfile", bal.Get_UserProfile)
		api.POST("/Update_Cususer", bal.Update_Cususer)

		// Shop Management
		api.POST("/Shop_overall_list", bal.Shop_overall_list)
		api.POST("/SaveShop", bal.SaveShop)
		api.POST("/DeleteShop", bal.DeleteShop)

		// Product Management
		api.POST("/GetProducts", bal.GetProducts)
		api.POST("/SaveProduct", bal.SaveProduct)
		api.POST("/DeleteProduct", bal.DeleteProduct)

		// Inventory & Customer Logic
		api.POST("/ProcessSale", bal.ProcessSale)
		api.GET("/GetIncomeHistory", bal.GetIncomeHistory)
		api.POST("/SaveIncome", bal.SaveIncome)
		api.GET("/GetStocks", bal.GetStocks)
		api.POST("/UpdateStock", bal.UpdateStock)
		api.GET("/GetAllCustomers", bal.GetAllCustomers)
		api.POST("/CreateCustomer", bal.CreateCustomer)
		api.POST("/GetCustomerLedger", bal.GetCustomerLedger)

		// Dashboard Analytics
		api.POST("/GetShopAnalytics", bal.GetShopAnalytics)
		api.POST("/GetRecentSales", bal.GetRecentSales)

		// API Health Check
		api.GET("/status", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{
				"status": "ok",
				"scope":  "api",
				"time":   time.Now().Format(time.RFC3339),
			})
		})
	}

	// 5. Serve React Static Files
	distPath := "../../Web/dist"
	router.Static("/assets", distPath+"/assets")
	router.StaticFile("/favicon.ico", distPath+"/favicon.ico")
	router.StaticFile("/logo.png", distPath+"/logo.png")
	router.StaticFile("/", distPath+"/index.html")

	// 6. SPA Handler (The Logic Fix for React Router)
	router.NoRoute(func(c *gin.Context) {
		path := c.Request.URL.Path

		// Logic: If someone requests a missing API or Image, return 404.
		// Otherwise, serve index.html to let React handle the page routing.
		if strings.HasPrefix(path, "/api") || strings.HasPrefix(path, "/uploads") {
			c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "Resource not found"})
			return
		}

		c.File(distPath + "/index.html")
	})

	// 7. Start Server (Dynamic Port for Render)
	port := os.Getenv("PORT")
	if port == "" {
		port = "5000" // Default for local
	}

	fmt.Printf("🚀 Q-Stocks Server starting on http://0.0.0.0:%s\n", port)

	// Use 0.0.0.0 to ensure Render's external network can bind to the process
	if err := router.Run("0.0.0.0:" + port); err != nil {
		log.Fatalf("❌ Server failed: %v", err)
	}
}
