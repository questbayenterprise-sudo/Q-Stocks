package Models

type AnalyticsResponse struct {
	TotalBookings int           `json:"total_bookings"`
	TotalRevenue  float64       `json:"total_revenue"`
	Occupancy     float64       `json:"occupancy"`
	WeeklyTrend   []WeeklyTrend `json:"weekly_trend"`
}

type WeeklyTrend struct {
	Day   string `json:"day"`
	Count int    `json:"count"`
}

type RecentBookingResponse struct {
	ID         int     `json:"id"`
	CourtName  string  `json:"court_name"`
	UserName   string  `json:"user_name"`
	BookingRef string  `json:"booking_ref"`
	Price      float64 `json:"price"`
	Status     string  `json:"status"`
	StartTime  string  `json:"start_time"`
}
