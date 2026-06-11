package main

import (
	"fmt"
	"log"
	"os"

	_ "github.com/lib/pq" // <-- required

	"github.com/gin-gonic/gin"

	bal "github.com/qsports/q-sports-booking-app/bal"
	"github.com/qsports/q-sports-booking-app/dal"
)

func main() {
	// Load environment variables
	err := dal.ConnectPostgres()
	if err != nil {
		log.Fatal("❌ Database connection failed: ", err)
	}
	fmt.Println("✅ Successfully connected to Q_Sports database via pgxpool")

	// Setup Gin
	router := gin.Default()

	// Create the directory if it doesn't exist
	os.MkdirAll("./uploads/venues", os.ModePerm)
	router.Static("/uploads", "./uploads")

	// --------------------
	// Auth / Login Routes
	// --------------------
	router.POST("/SignIn", bal.SignIn)
	router.GET("/Logout", bal.Logout)
	router.GET("/VerifyEmail", bal.VerifyEmail)
	router.POST("/Create_Cususer", bal.Create_Cususer)
	router.POST("/Update_Cususer", bal.Update_Cususer)
	router.POST("/Delete_Cususer", bal.Delete_Cususer)
	router.POST("/Get_UserProfile", bal.Get_UserProfile)
	router.GET("/GetAllUsers", bal.GetAllUsers)
	router.POST("/UpdateUserRole", bal.UpdateUserRole)
	router.POST("/Send_OTP", bal.Send_OTP)
	router.POST("/Verify_OTP", bal.Verify_OTP)

	// --------------------
	// Dashboard Routes
	// --------------------

	router.POST("/GetRecentBookingsAdmin", bal.GetRecentBookingsAdmin)
	router.POST("/GetTurfAnalytics", bal.GetTurfAnalytics)

	// --------------------
	// Venue Details & Booking Routes
	// --------------------
	router.POST("/Venue_overall_list", bal.Venue_overall_list)
	router.POST("/InsertVenue", bal.InsertVenue)

	router.POST("/EditVenue", bal.EditVenue)
	router.POST("/UpdateVenue", bal.UpdateVenue)
	router.POST("/GetVenueSlots", bal.GetVenueSlots)
	router.POST("/GetBookingQRData", bal.GetBookingQRData)
	router.POST("/InitiateBooking", bal.InitiateBooking)
	router.POST("/Payment_Callback", bal.Payment_Callback)
	router.POST("/GetMyBookingHistory", bal.GetMyBookingHistory)
	router.POST("/DeleteVenue", bal.DeleteVenue)
	router.POST("/GetExistingBookings", bal.GetExistingBookings)
	router.GET("/Selected_venue_details", bal.Selected_venue_details)
	router.GET("/Venue_owner_currentlist", bal.Venue_owner_currentlist)
	router.POST("/Selected_venue_booking", bal.Selected_venue_booking)

	// --------------------
	// Settings Routes
	// --------------------
	router.GET("/Get_Sports", bal.Get_Sports)
	router.GET("/GetMasterDetailsForVenueAdd", bal.GetMasterDetailsForVenueAdd)
	router.GET("/Get_Cities", bal.Get_Cities)
	router.POST("/Insert_City", bal.Insert_City)
	router.POST("/Update_UserLocation", bal.Update_UserLocation)
	router.POST("/Save_FcmToken", bal.Save_FcmToken)
	router.POST("/Remove_FcmToken", bal.Remove_FcmToken)
	router.POST("/Test_Notification", bal.Test_Notification)
	router.POST("/Debug_Notification", bal.Debug_Notification)
	router.POST("/GetNotifications", bal.GetNotifications)
	router.POST("/MarkNotificationRead", bal.MarkNotificationRead)
	router.POST("/GetUnreadNotificationCount", bal.GetUnreadNotificationCount)
	router.GET("/Get_AdminSettings", bal.Get_AdminSettings)
	router.POST("/Update_AdminSettings", bal.Update_AdminSettings)
	router.GET("/GetVenueMappings", bal.GetVenueMappings)
	router.POST("/AddVenueMapping", bal.AddVenueMapping)
	router.POST("/RemoveVenueMapping", bal.RemoveVenueMapping)
	router.GET("/GetVenueListForMapping", bal.GetVenueListForMapping)
	router.GET("/GetUserListForMapping", bal.GetUserListForMapping)
	router.POST("/Get_UserSettings", bal.Get_UserSettings)
	router.POST("/Update_UserSettings", bal.Update_UserSettings)
	router.PUT("/User_personal_settings_edit", bal.User_personal_settings_edit)
	router.PUT("/Update_user_personal_seettings", bal.Update_user_personal_seettings)
	router.GET("/Customer_booking_history", bal.Customer_booking_history)
	router.GET("/Customer_current_booking", bal.Customer_current_booking)

	// --------------------
	// QR Scan Routes
	// --------------------
	router.POST("/ValidateScanQR", bal.ValidateScanQR)
	router.POST("/UpdateBookingStatus", bal.UpdateBookingStatus)
	router.POST("/GetBookingDetail", bal.GetBookingDetail)

	// --------------------
	// Likes / Favorites Routes
	// --------------------
	router.POST("/ToggleVenueLike", bal.ToggleVenueLike)
	router.POST("/CheckVenueLike", bal.CheckVenueLike)
	router.POST("/GetVenueLikeCount", bal.GetVenueLikeCount)
	router.POST("/GetLikedVenues", bal.GetLikedVenues)

	// --------------------
	// Chat Routes
	// --------------------
	router.POST("/CreateConversation", bal.CreateConversation)
	router.POST("/GetConversations", bal.GetConversations)
	router.POST("/SendMessage", bal.SendMessage)
	router.POST("/GetMessages", bal.GetMessages)
	router.POST("/MarkMessagesRead", bal.MarkMessagesRead)
	router.POST("/GetUnreadCount", bal.GetUnreadCount)
	router.POST("/GetChatContacts", bal.GetChatContacts)

	// --------------------
	// Health Check Route
	// --------------------
	router.GET("/status", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status": "ok",
			"app":    "q-sports-booking-app",
		})
	})

	// Start server
	if err := router.Run(":5000"); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}
