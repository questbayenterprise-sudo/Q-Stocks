package bal

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5"
	Models "github.com/qsports/q-sports-booking-app/Models"
	dal "github.com/qsports/q-sports-booking-app/dal"
)

type search_venue_list struct {
	Id string `json:"id"`

	Search          string  `json:"search"`
	Pageno          int     `json:"pageno"`
	Pagesize        int     `json:"pagesize"`
	Distancebetween float64 `json:"distancebetween"`
	Rating          float64 `json:"rating"`
	Sortby          string  `json:"sortby"`
	Latitude        float64 `json:"latitude"`
	Longitude       float64 `json:"longitude"`
	UserID          string  `json:"user_id"`
	UserType        string  `json:"user_type"`
	CityID          int     `json:"city_id"`
}

type venue_booking_details struct {
	Venue_id     string `json:"venue_id"`
	Court_id     string `json:"court_id"`
	Slot_id      string `json:"slot_id"`
	Priceperslot string `json:"priceperslot"`
	CusUserId    string `json:"CusUserId"`
}

// This struct matches the form tags sent from Flutter
type VenueForm struct {
	Name         string  `form:"name" binding:"required"`
	Location     string  `form:"location" binding:"required"`
	Price        float64 `form:"price" binding:"required"`
	Capacity     int     `form:"capacity"`
	Description  string  `form:"description"`
	ContactPhone string  `form:"contact_phone"`
	ContactEmail string  `form:"contact_email"`
}

type VenueSport struct {
	ID   int    `json:"id"`
	Name string `json:"name"`
}

type VenueDB struct {
	ID          int          `json:"id"`
	Name        string       `json:"name"`
	Location    string       `json:"location"`
	Price       float64      `json:"price"`
	Capacity    int          `json:"capacity"`
	Description string       `json:"description"`
	ImageURL    string       `json:"image_url"`
	Slots       []Slot       `json:"slots"`
	Sports      []string     `json:"sports"`
	SportsData  []VenueSport `json:"sports_data"`
	DistanceKm  float64      `json:"distance_km"`
}

type Slot struct {
	ST string  `json:"ST"`
	ET string  `json:"ET"`
	PR float64 `json:"PR"`
}

func Venue_overall_list(c *gin.Context) {
	var searchstruct search_venue_list
	ctx := c.Request.Context()

	if err := c.ShouldBindJSON(&searchstruct); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid Request"})
		return
	} else {

		userType := strings.ToLower(searchstruct.UserType)
		hasLocation := searchstruct.Latitude != 0 && searchstruct.Longitude != 0

		venues := []VenueDB{}

		// ──────────────────────────────────────────
		// CASE 1: Admin → fetch ALL venues
		// ──────────────────────────────────────────
		if userType == "admin" {
			query := `SELECT id, name, location, price, description, image_url FROM venues WHERE is_active = true`
			rows1, err := dal.Query(ctx, query)
			if err != nil {
				log.Printf("Query error: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Database error"})
				return
			}
			defer rows1.Close()
			for rows1.Next() {
				var v VenueDB
				if err := rows1.Scan(&v.ID, &v.Name, &v.Location, &v.Price, &v.Description, &v.ImageURL); err != nil {
					log.Printf("Scan error: %v", err)
					continue
				}
				v.ImageURL = filepath.ToSlash(v.ImageURL)
				v.Sports = []string{}
				v.SportsData = []VenueSport{}
				venues = append(venues, v)
			}

		// ──────────────────────────────────────────
		// CASE 2: Vendor / Owner / Manager → mapped venues only
		// ──────────────────────────────────────────
		} else if userType == "vendor" || userType == "owner" || userType == "manager" {
			query := `
				SELECT v.id, v.name, v.location, v.price, v.description, v.image_url
				FROM venues v
				INNER JOIN user_venue_mapping m ON m.venue_id = v.id AND m.is_active = true
				WHERE m.user_id = $1 AND v.is_active = true
			`
			rows1, err := dal.Query(ctx, query, searchstruct.UserID)
			if err != nil {
				log.Printf("Query error: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Database error"})
				return
			}
			defer rows1.Close()
			for rows1.Next() {
				var v VenueDB
				if err := rows1.Scan(&v.ID, &v.Name, &v.Location, &v.Price, &v.Description, &v.ImageURL); err != nil {
					log.Printf("Scan error: %v", err)
					continue
				}
				v.ImageURL = filepath.ToSlash(v.ImageURL)
				v.Sports = []string{}
				v.SportsData = []VenueSport{}
				venues = append(venues, v)
			}

		// ──────────────────────────────────────────
		// CASE 3: User / Guest → location-based
		// ──────────────────────────────────────────
		} else {
			lat := searchstruct.Latitude
			lng := searchstruct.Longitude

			// If no GPS coords but city_id provided, get city coordinates
			if !hasLocation && searchstruct.CityID > 0 {
				err := dal.DB.QueryRow(ctx,
					`SELECT latitude, longitude FROM cities WHERE id = $1 AND is_active = true`,
					searchstruct.CityID,
				).Scan(&lat, &lng)
				if err == nil && lat != 0 && lng != 0 {
					hasLocation = true
				}
			}

			if hasLocation {
				// Haversine distance query
				query := `
					SELECT v.id, v.name, v.location, v.price, v.description, v.image_url,
						COALESCE(
							(6371 * acos(
								LEAST(1.0, GREATEST(-1.0,
									cos(radians($1)) * cos(radians(c.latitude)) *
									cos(radians(c.longitude) - radians($2)) +
									sin(radians($1)) * sin(radians(c.latitude))
								))
							)), 9999
						) AS distance_km
					FROM venues v
					LEFT JOIN cities c ON LOWER(v.location) = LOWER(c.name) AND c.is_active = true
					WHERE v.is_active = true
					ORDER BY distance_km ASC
				`
				rows1, err := dal.Query(ctx, query, lat, lng)
				if err != nil {
					log.Printf("Query error: %v", err)
					c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Database error"})
					return
				}
				defer rows1.Close()
				for rows1.Next() {
					var v VenueDB
					if err := rows1.Scan(&v.ID, &v.Name, &v.Location, &v.Price, &v.Description, &v.ImageURL, &v.DistanceKm); err != nil {
						log.Printf("Scan error: %v", err)
						continue
					}
					v.ImageURL = filepath.ToSlash(v.ImageURL)
					v.Sports = []string{}
				v.SportsData = []VenueSport{}
					venues = append(venues, v)
				}
			} else {
				// Fallback — load all venues
				query := `SELECT id, name, location, price, description, image_url FROM venues WHERE is_active = true`
				rows1, err := dal.Query(ctx, query)
				if err != nil {
					log.Printf("Query error: %v", err)
					c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Database error"})
					return
				}
				defer rows1.Close()
				for rows1.Next() {
					var v VenueDB
					if err := rows1.Scan(&v.ID, &v.Name, &v.Location, &v.Price, &v.Description, &v.ImageURL); err != nil {
						log.Printf("Scan error: %v", err)
						continue
					}
					v.ImageURL = filepath.ToSlash(v.ImageURL)
					v.Sports = []string{}
				v.SportsData = []VenueSport{}
					venues = append(venues, v)
				}
			}
		}

		// Fetch sports for all venues in one query (with IDs)
		sportsQuery := `
			SELECT DISTINCT c.venue_id, s.id, s.name
			FROM courts c
			JOIN sports s ON s.id = c.sport_id
			WHERE c.venue_id IS NOT NULL
			ORDER BY c.venue_id, s.name
		`
		sRows, sErr := dal.Query(ctx, sportsQuery)
		if sErr == nil {
			defer sRows.Close()
			sportsMap := map[int][]string{}
			sportsDataMap := map[int][]VenueSport{}
			for sRows.Next() {
				var venueID int
				var sportID int
				var sportName string
				if err := sRows.Scan(&venueID, &sportID, &sportName); err == nil {
					sportsMap[venueID] = append(sportsMap[venueID], sportName)
					sportsDataMap[venueID] = append(sportsDataMap[venueID], VenueSport{ID: sportID, Name: sportName})
				}
			}
			for i := range venues {
				if sports, ok := sportsMap[venues[i].ID]; ok {
					venues[i].Sports = sports
				}
				if sd, ok := sportsDataMap[venues[i].ID]; ok {
					venues[i].SportsData = sd
				}
			}
		}
		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"rows":    venues,
		})
	}
}

func EditVenue(c *gin.Context) {
	var searchstruct search_venue_list
	ctx := c.Request.Context()

	if err := c.ShouldBindJSON(&searchstruct); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid Request"})
		return
	} else {

		query := `
		SELECT json_build_object(
			'id', v.id,
			'name', v.name,
			'location', v.location,
			'price', v.price,
			'description', v.description,
			'image_url', v.image_url,
			'slots', COALESCE(
				(SELECT json_agg(json_build_object(
					'ST', TO_CHAR(ts.start_time, 'HH12:MIPM'),
					'ET', TO_CHAR(ts.end_time, 'HH12:MIPM'),
					'PR', ts.price
				)) FROM time_slots ts WHERE ts.court_id = v.id), '[]'
			)
		)
		FROM venues v WHERE v.id = $1`

		// rows, err := dal.Query(ctx, query, "%"+searchstruct.Search+"%", searchstruct.PageSize, offset)
		rows1, err := dal.Query(ctx, query, searchstruct.Id)

		if err != nil {
			log.Printf("Query error: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Database error"})
			return
		}
		defer rows1.Close()

		venues := []VenueDB{}
		for rows1.Next() {
			var raw []byte
			if err := rows1.Scan(&raw); err != nil {
				log.Println(err)
				continue
			}

			var v VenueDB
			if err := json.Unmarshal(raw, &v); err != nil {
				log.Println(err)
				continue
			}

			v.ImageURL = filepath.ToSlash(v.ImageURL)
			venues = append(venues, v)
		}
		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"rows":    venues,
		})
	}
}

// --- GET SPORTS MASTER LIST ---
// --- COMBINED MASTER DATA FOR VENUE ADD ---
func GetMasterDetailsForVenueAdd(c *gin.Context) {
	ctx := c.Request.Context()

	// 1. Fetch Sports
	type Sport struct {
		ID   int    `json:"id"`
		Name string `json:"name"`
	}
	var sports []Sport
	sRows, sErr := dal.Query(ctx, `SELECT id, name FROM sports ORDER BY name`)
	if sErr == nil {
		defer sRows.Close()
		for sRows.Next() {
			var s Sport
			if err := sRows.Scan(&s.ID, &s.Name); err == nil {
				sports = append(sports, s)
			}
		}
	}

	// 2. Fetch Cities
	var cities []string
	cRows, cErr := dal.Query(ctx, `SELECT name FROM cities WHERE is_active = true AND state = 'Tamil Nadu' ORDER BY name`)
	if cErr == nil {
		defer cRows.Close()
		for cRows.Next() {
			var name string
			if err := cRows.Scan(&name); err == nil {
				cities = append(cities, name)
			}
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"sports":  sports,
		"cities":  cities,
	})
}

func Get_Sports(c *gin.Context) {
	ctx := c.Request.Context()
	query := `SELECT id, name FROM sports ORDER BY name`
	rows, err := dal.Query(ctx, query)
	if err != nil {
		log.Printf("Error fetching sports: %v", err)
		c.JSON(http.StatusOK, gin.H{"success": false, "message": "Database error"})
		return
	}
	defer rows.Close()

	type Sport struct {
		ID   int    `json:"id"`
		Name string `json:"name"`
	}
	var sports []Sport
	for rows.Next() {
		var s Sport
		if err := rows.Scan(&s.ID, &s.Name); err == nil {
			sports = append(sports, s)
		}
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "data": sports})
}

func InsertVenue(c *gin.Context) {
	ctx := c.Request.Context()
	var Venue_owner_id string
	// 1. Get Form Fields
	name := c.PostForm("name")
	location := c.PostForm("location")
	price := c.PostForm("price")
	description := c.PostForm("description")
	slotsRaw := c.PostForm("slots")
	gamesRaw := c.PostForm("games")
	if c.PostForm("userid") != "" {
		Venue_owner_id = c.PostForm("userid")
	}

	// 2. Parse Slots (Check format before starting Transaction)
	type VenueSlot struct {
		ST string `json:"ST"`
		ET string `json:"ET"`
		PR string `json:"PR"`
	}
	var slots []VenueSlot
	if slotsRaw != "" {
		if err := json.Unmarshal([]byte(slotsRaw), &slots); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid slots JSON"})
			return
		}
	}

	// 2b. Parse Games/Sports
	type VenueGameInput struct {
		ID   *int   `json:"id"`
		Game string `json:"game"`
	}
	var games []VenueGameInput
	if gamesRaw != "" {
		if err := json.Unmarshal([]byte(gamesRaw), &games); err != nil {
			log.Printf("Games parse error: %v", err)
		}
	}

	// 3. Handle Image Upload (Do this before Tx to avoid keeping DB connection open during IO)
	file, err := c.FormFile("image")
	var imagePath string
	if err == nil {
		uploadDir := "uploads/venues"
		os.MkdirAll(uploadDir, os.ModePerm)
		filename := fmt.Sprintf("%d_%s", time.Now().Unix(), filepath.Base(file.Filename))
		imagePath = filepath.Join(uploadDir, filename)
		c.SaveUploadedFile(file, imagePath)
	}

	// ────────────────────────────────────────────────
	// START TRANSACTION
	// ────────────────────────────────────────────────
	tx, err := dal.DB.Begin(ctx)
	if err != nil {
		log.Printf("Transaction Start Error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "DB Transaction Error"})
		return
	}

	// Magic line: rollback automatically if function returns before Commit
	defer tx.Rollback(ctx)

	// 4. Insert Venue into venues table
	vQuery := `INSERT INTO venues (name, location, price, description, image_url,created_by) 
			  VALUES ($1, $2, $3, $4, $5,$6) RETURNING id`
	var lastID int

	// Note: We use tx.QueryRow, NOT dal.QueryRow
	err = tx.QueryRow(ctx, vQuery, name, location, price, description, imagePath, Venue_owner_id).Scan(&lastID)
	if err != nil {
		log.Printf("Venue Insert Error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Failed to save venue details"})
		return // Rollback triggered
	}
	if Venue_owner_id != "" {
		xQuery := `insert into user_venue_mapping(user_id,venue_id)
		values($1,$2) RETURNING id`
		var MappedlastID int

		// Note: We use tx.QueryRow, NOT dal.QueryRow
		err = tx.QueryRow(ctx, xQuery, Venue_owner_id, lastID).Scan(&MappedlastID)
		if err != nil {
			log.Printf("Venue mapping Insert Error: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Failed to save venue details"})
			return // Rollback triggered
		}
	}

	// 5. Insert Slots into time_slots table
	if len(slots) > 0 {
		sQuery := `INSERT INTO time_slots (court_id, start_time, end_time, is_booked, price,venue_id) 
				  VALUES ($1, $2, $3, $4,$5,$6)`

		now := time.Now()
		for _, s := range slots {
			st, errS := time.Parse("3:04PM", s.ST)
			et, errE := time.Parse("3:04PM", s.ET)

			if errS != nil || errE != nil {
				log.Printf("Time parsing error for slot: %s - %s", s.ST, s.ET)
				continue
			}

			startTs := time.Date(now.Year(), now.Month(), now.Day(), st.Hour(), st.Minute(), 0, 0, time.Local)
			endTs := time.Date(now.Year(), now.Month(), now.Day(), et.Hour(), et.Minute(), 0, 0, time.Local)

			// Note: We use tx.Exec inside the loop
			_, err := tx.Exec(ctx, sQuery, lastID, startTs, endTs, false, s.PR, lastID)
			if err != nil {
				log.Printf("Slot Insert Error: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Failed to save venue slots"})
				return // Rollback triggered
			}
		}
	}

	// 5b. Insert Sports into courts table (venue-sport mapping)
	if len(games) > 0 {
		for _, g := range games {
			sportID := 0
			if g.ID != nil && *g.ID > 0 {
				sportID = *g.ID
			} else {
				// Look up sport by name, insert if not exists
				err := tx.QueryRow(ctx, `SELECT id FROM sports WHERE LOWER(name) = LOWER($1)`, g.Game).Scan(&sportID)
				if err != nil {
					// Insert new sport
					err = tx.QueryRow(ctx, `INSERT INTO sports (name) VALUES ($1) RETURNING id`, g.Game).Scan(&sportID)
					if err != nil {
						log.Printf("Sport insert error: %v", err)
						continue
					}
				}
			}
			_, err := tx.Exec(ctx,
				`INSERT INTO courts (venue_id, sport_id, name, price_per_hour) VALUES ($1, $2, $3, $4)`,
				lastID, sportID, g.Game, price,
			)
			if err != nil {
				log.Printf("Court insert error: %v", err)
			}
		}
	}

	// 6. COMMIT TRANSACTION
	if err := tx.Commit(ctx); err != nil {
		log.Printf("Commit Error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Final save failed"})
		return
	}

	// Success Response
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Venue and slots saved successfully",
		"id":      lastID,
	})
}

func UpdateVenue(c *gin.Context) {
	ctx := c.Request.Context()

	// 1. Get Form Fields
	venueIDStr := c.PostForm("id") // Required for Update
	name := c.PostForm("name")
	location := c.PostForm("location")
	price := c.PostForm("price")
	description := c.PostForm("description")
	slotsRaw := c.PostForm("slots")
	gamesRaw := c.PostForm("games")
	existingImage := c.PostForm("existing_image") // From Flutter Repo

	if venueIDStr == "" {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Venue ID is required"})
		return
	}
	venueID, _ := strconv.Atoi(venueIDStr)

	// 2. Parse Slots JSON
	type VenueSlot struct {
		ST string `json:"ST"`
		ET string `json:"ET"`
		PR string `json:"PR"`
	}
	var slots []VenueSlot
	if slotsRaw != "" {
		if err := json.Unmarshal([]byte(slotsRaw), &slots); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid slots format"})
			return
		}
	}

	// 2b. Parse Games/Sports
	type VenueGameInput struct {
		ID   *int   `json:"id"`
		Game string `json:"game"`
	}
	var games []VenueGameInput
	if gamesRaw != "" {
		if err := json.Unmarshal([]byte(gamesRaw), &games); err != nil {
			log.Printf("Games parse error: %v", err)
		}
	}

	// 3. Handle Image Upload
	file, err := c.FormFile("image")
	var imagePath string
	if err == nil {
		// New image uploaded
		uploadDir := "uploads/venues"
		os.MkdirAll(uploadDir, os.ModePerm)
		filename := fmt.Sprintf("%d_%s", time.Now().Unix(), filepath.Base(file.Filename))
		imagePath = filepath.Join(uploadDir, filename)
		c.SaveUploadedFile(file, imagePath)
	} else {
		// No new image, use the existing path sent from Flutter
		imagePath = existingImage
	}

	// ────────────────────────────────────────────────
	// START TRANSACTION
	// ────────────────────────────────────────────────
	tx, err := dal.DB.Begin(ctx)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "DB Error"})
		return
	}
	defer tx.Rollback(ctx)

	// 4. Update venues table
	vQuery := `UPDATE venues SET name=$1, location=$2, price=$3, description=$4, image_url=$5, updated_at=CURRENT_TIMESTAMP 
			   WHERE id=$6`
	_, err = tx.Exec(ctx, vQuery, name, location, price, description, imagePath, venueID)
	if err != nil {
		log.Printf("Venue Update Error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Failed to update venue details"})
		return
	}

	// 5. Update Slots (Delete then Re-insert)
	// Delete existing slots first
	_, err = tx.Exec(ctx, `DELETE FROM time_slots WHERE venue_id = $1`, venueID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Failed to clear old slots"})
		return
	}

	// Insert new slots (Reuse your logic from InsertVenue)
	if len(slots) > 0 {
		sQuery := `INSERT INTO time_slots (court_id, start_time, end_time, is_booked, price, venue_id) 
				  VALUES ($1, $2, $3, $4, $5, $6)`

		now := time.Now()
		for _, s := range slots {
			st, errS := time.Parse("3:04PM", s.ST)
			et, errE := time.Parse("3:04PM", s.ET)

			if errS != nil || errE != nil {
				continue
			}

			startTs := time.Date(now.Year(), now.Month(), now.Day(), st.Hour(), st.Minute(), 0, 0, time.Local)
			endTs := time.Date(now.Year(), now.Month(), now.Day(), et.Hour(), et.Minute(), 0, 0, time.Local)

			_, err := tx.Exec(ctx, sQuery, venueID, startTs, endTs, false, s.PR, venueID)
			if err != nil {
				log.Printf("Slot Insert Error: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Failed to update slots"})
				return
			}
		}
	}

	// 5b. Update Sports/Courts (Delete then Re-insert)
	_, _ = tx.Exec(ctx, `DELETE FROM courts WHERE venue_id = $1`, venueID)
	if len(games) > 0 {
		for _, g := range games {
			sportID := 0
			if g.ID != nil && *g.ID > 0 {
				sportID = *g.ID
			} else {
				err := tx.QueryRow(ctx, `SELECT id FROM sports WHERE LOWER(name) = LOWER($1)`, g.Game).Scan(&sportID)
				if err != nil {
					err = tx.QueryRow(ctx, `INSERT INTO sports (name) VALUES ($1) RETURNING id`, g.Game).Scan(&sportID)
					if err != nil {
						log.Printf("Sport insert error: %v", err)
						continue
					}
				}
			}
			_, err := tx.Exec(ctx,
				`INSERT INTO courts (venue_id, sport_id, name, price_per_hour) VALUES ($1, $2, $3, $4)`,
				venueID, sportID, g.Game, price,
			)
			if err != nil {
				log.Printf("Court insert error: %v", err)
			}
		}
	}

	// 6. COMMIT TRANSACTION
	if err := tx.Commit(ctx); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Final update failed"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Venue updated successfully",
	})
}

func Selected_venue_details(c *gin.Context) {

	if c.PostForm("venueID") != "" {

		ctx := c.Request.Context()
		rows, err := dal.ExecSelectJSON(
			ctx,
			`Select query to get the venue list`,
			c.PostForm("venueID"),
		)
		if err != nil {
			c.JSON(http.StatusOK, gin.H{
				"success": false,
				"status":  http.StatusBadRequest,
				"message": "DB Issue",
				"data":    nil,
			})
		} else {
			c.JSON(http.StatusOK, gin.H{
				"success": true,
				"status":  http.StatusBadRequest,
				"message": "Request handled successfully",
				"data":    rows,
			})
		}

	} else {
		c.JSON(http.StatusOK, gin.H{
			"success": false,
			"status":  http.StatusBadRequest,
			"message": "Invalid Request",
			"data":    nil,
		})
	}

}

func Selected_venue_booking(c *gin.Context) {
	ctx := c.Request.Context()

	var venue_booking_detailsstruct venue_booking_details
	if err := c.ShouldBindJSON(&venue_booking_detailsstruct); err != nil {
		c.JSON(http.StatusOK, gin.H{
			"success": false,
			"status":  http.StatusBadRequest,
			"message": "Invalid Request",
			"data":    nil,
		})
	} else {

		cusUserId := venue_booking_detailsstruct.CusUserId
		venueId := venue_booking_detailsstruct.Venue_id
		courtId := venue_booking_detailsstruct.Court_id
		slotId := venue_booking_detailsstruct.Slot_id
		insertQueryBlock := `INSERT INTO bookings (user_id, court_id, venue_id, slot_id) VALUES ($1, $2, $3, $4)`

		updateQueryBlock := `UPDATE time_slots SET is_booked = true WHERE venue_id = $1 AND court_id = $2 AND slot_timingid = $3`

		result := dal.Insert_venue_booking(
			ctx,
			cusUserId,
			courtId,
			venueId,
			slotId,
			insertQueryBlock,
			updateQueryBlock,
		)

		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"status":  http.StatusBadRequest,
			"message": "Booking details inserted successfully",
			"data":    result,
		})

	}
}

func Venue_owner_currentlist(c *gin.Context) {
	if c.PostForm("ownersID") != "" {
		c.JSON(http.StatusOK, gin.H{
			"success": false,
			"status":  http.StatusBadRequest,
			"message": "Request handled successfully",
			"data":    nil,
		})
	} else {
		c.JSON(http.StatusOK, gin.H{
			"success": false,
			"status":  http.StatusBadRequest,
			"message": "Invalid Request",
			"data":    nil,
		})
	}
}

func DeleteVenue(c *gin.Context) {
	ctx := c.Request.Context()

	// 1. Parse Request Body
	// Assuming Flutter sends {"id": "123"}
	type DeleteRequest struct {
		ID string `json:"id" binding:"required"`
	}
	var req DeleteRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid request format"})
		return
	}

	// 2. Convert ID to Integer (Since your DB uses INTEGER)
	venueID, err := strconv.Atoi(req.ID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid Venue ID"})
		return
	}

	// ────────────────────────────────────────────────
	// START TRANSACTION
	// ────────────────────────────────────────────────
	tx, err := dal.DB.Begin(ctx)
	if err != nil {
		log.Printf("Delete Transaction Start Error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Database error"})
		return
	}

	// Rollback automatically if function returns before Commit
	defer tx.Rollback(ctx)

	// 4. (Optional) Deactivate/Remove associated Slots
	// You might want to prevent these slots from appearing in search results
	sQuery := `DELETE FROM time_slots WHERE venue_id = $1`
	// OR if you have a soft delete on slots: `UPDATE time_slots SET is_booked = true WHERE venue_id = $1`

	_, err = tx.Exec(ctx, sQuery, venueID)
	if err != nil {
		log.Printf("Slots Removal Error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Failed to remove associated slots"})
		return
	}
	// 3. Update Venue to is_active = false (Soft Delete)
	vQuery := `UPDATE venues SET is_active = false, updated_at = CURRENT_TIMESTAMP WHERE id = $1`
	res, err := tx.Exec(ctx, vQuery, venueID)
	if err != nil {
		log.Printf("Venue Deactivation Error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Failed to deactivate venue"})
		return
	}

	// Check if the venue actually existed
	if res.RowsAffected() == 0 {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "Venue not found"})
		return
	}

	// 5. COMMIT TRANSACTION
	if err := tx.Commit(ctx); err != nil {
		log.Printf("Delete Commit Error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Final deletion failed"})
		return
	}

	// Success Response
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Venue and associated slots deactivated successfully",
	})
}

// 1. Structs for JSON mapping
type AvailabilityRequest struct {
	VenueID   int    `json:"venue_id"`
	Date      string `json:"date"`       // format: YYYY-MM-DD
	StartTime string `json:"start_time"` // format: 3:04PM
	EndTime   string `json:"end_time"`
	Id        string `json:"id"`
}

// 2. Handler to fetch all pre-defined slots for a venue
func GetVenueSlots(c *gin.Context) {
	ctx := c.Request.Context()
	var searchstruct AvailabilityRequest

	if err := c.ShouldBindJSON(&searchstruct); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid Request"})
		return
	}
	// Query pre-defined slots from time_slots table
	query := `SELECT id, start_time, end_time, price, is_booked 
	          FROM time_slots WHERE venue_id = $1`

	rows, err := dal.DB.Query(ctx, query, searchstruct.Id)
	if err != nil {
		c.JSON(500, gin.H{"success": false, "message": "Failed to fetch slots"})
		return
	}
	defer rows.Close()

	var slots []gin.H
	for rows.Next() {
		var id int
		var st, et time.Time
		var price float64
		var isBooked bool
		rows.Scan(&id, &st, &et, &price, &isBooked)

		slots = append(slots, gin.H{
			"id":        id,
			"range":     fmt.Sprintf("%s - %s", st.Format("03:04 PM"), et.Format("03:04 PM")),
			"price":     price,
			"is_booked": isBooked,
		})
	}

	c.JSON(200, gin.H{"success": true, "slots": slots})
}

// 3. Handler for Custom Range Availability Check
func CheckSlotAvailability(c *gin.Context) {
	var req AvailabilityRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"success": false, "message": "Invalid Request"})
		return
	}

	ctx := c.Request.Context()

	// Convert requested times to full timestamps for comparison
	layout := "2006-01-02 3:04PM"
	reqStart, _ := time.Parse(layout, req.Date+" "+req.StartTime)
	reqEnd, _ := time.Parse(layout, req.Date+" "+req.EndTime)

	// SQL Overlap Check: Find any existing booking that overlaps with requested time
	// Logic: (StartA < EndB) AND (EndA > StartB)
	checkQuery := `
		SELECT COUNT(*) FROM bookings b
		JOIN time_slots s ON b.slot_id = s.id
		WHERE b.venue_id = $1 
		AND b.status = 'CONFIRMED'
		AND (($2 < s.end_time) AND ($3 > s.start_time))`

	var count int
	err := dal.DB.QueryRow(ctx, checkQuery, req.VenueID, reqStart, reqEnd).Scan(&count)

	if err != nil {
		c.JSON(500, gin.H{"success": false, "message": "DB error"})
		return
	}

	c.JSON(200, gin.H{
		"success":   true,
		"available": count == 0,
	})
}

// Request struct to match the JSON body
type HistoryRequest struct {
	Id   string `json:"venue_id"`
	Date string `json:"date"` // Format: 2024-05-20
}

func GetExistingBookings(c *gin.Context) {
	ctx := c.Request.Context()
	var req HistoryRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid Request"})
		return
	}

	// Query: Join bookings with mapping and users to get names and times
	// We filter by venue_id and use DATE() to match the booked_at timestamp
	query := `
		SELECT 
			bm.start_time, 
			bm.end_time, 
			u.username as user_name
		FROM bookings b
		JOIN bookings_mapping bm ON b.slot_id = bm.slot_id
		JOIN users u ON b.user_id = u.id
		WHERE b.venue_id = $1 
		AND b.status = 'CONFIRMED'
		AND DATE(b.booked_at) = $2
	`

	rows, err := dal.DB.Query(ctx, query, req.Id, req.Date)
	if err != nil {
		log.Printf("History Query Error: %v", err)
		c.JSON(500, gin.H{"success": false, "message": "Failed to fetch history"})
		return
	}
	defer rows.Close()

	var history []gin.H
	for rows.Next() {
		var st, et, user string
		if err := rows.Scan(&st, &et, &user); err != nil {
			continue
		}
		history = append(history, gin.H{
			"time_range": fmt.Sprintf("%s - %s", st, et),
			"user":       user,
		})
	}

	// If no bookings found, return empty list instead of null
	if history == nil {
		history = []gin.H{}
	}

	c.JSON(200, gin.H{
		"success": true,
		"data":    history,
	})
}

// Additive Go Service Logic
type BookingService struct {
	db interface{} // Replace with your actual database connection type
}

type BookingHandler struct {
	service *BookingService
}

type BookingRequest struct {
	CusUserId string `json:"CusUserId"`
	CourtId   string `json:"court_id"`
	VenueId   string `json:"venue_id"`
	SlotId    string `json:"slot_id"`
	StartTime string `json:"start_time"`
	EndTime   string `json:"end_time"`
	Date      string `json:"date"`
	Sports_id string `json:"sports_id"`
	Amount    string `json:"amount"`
}

type BookingV2Response struct {
	BookingID int    `json:"booking_id"`
	Success   bool   `json:"success"`
	Message   string `json:"message"`
}

type BookingQRDB struct {
	ID        int       `json:"id"`
	VenueName string    `json:"venue_name"`
	StartTime time.Time `json:"start_time"`
	EndTime   time.Time `json:"end_time"`
	Status    string    `json:"status"`
}
type BookingQRRequest struct {
	BookingID int `json:"booking_id" binding:"required"`
}

func InitiateBooking(c *gin.Context) {
	ctx := c.Request.Context()

	var req BookingRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"success": false, "message": err.Error()})
		return
	}

	// Fetch payment flag from admin settings (source of truth)
	var isPaymentEnabled bool
	err := dal.DB.QueryRow(ctx, "SELECT COALESCE(enable_payment, false) FROM tbl_general_settings LIMIT 1").Scan(&isPaymentEnabled)
	if err != nil {
		isPaymentEnabled = false // Default to disabled if settings not found
	}

	// Determine initial status based on payment flag
	initialStatus := "CONFIRMED"
	paymentStatus := "NA"
	if isPaymentEnabled {
		initialStatus = "PENDING"
		paymentStatus = "PENDING"
	}

	// START TRANSACTION
	tx, err := dal.DB.Begin(ctx)
	if err != nil {
		c.JSON(500, gin.H{"success": false, "message": err.Error()})
		return
	}
	defer tx.Rollback(ctx)

	// Convert '0' or empty to nil for optional foreign keys
	nullIfZero := func(val string) interface{} {
		if val == "" || val == "0" {
			return nil
		}
		return val
	}

	// Auto-resolve court_id from venue_id + sports_id if not provided
	courtId := req.CourtId
	if (courtId == "" || courtId == "0") && req.Sports_id != "" && req.Sports_id != "0" {
		var resolvedCourtId int
		err := tx.QueryRow(ctx,
			`SELECT id FROM courts WHERE venue_id = $1 AND sport_id = $2 LIMIT 1`,
			req.VenueId, req.Sports_id,
		).Scan(&resolvedCourtId)
		if err == nil {
			courtId = strconv.Itoa(resolvedCourtId)
		}
	}

	// Generate booking reference: QS-YYYYMMDD-XXXX
	now := time.Now()
	datePrefix := now.Format("20060102")
	var seqNum int
	_ = tx.QueryRow(ctx,
		`SELECT COALESCE(MAX(id), 0) + 1 FROM bookings`,
	).Scan(&seqNum)
	bookingRef := fmt.Sprintf("QS-%s-%04d", datePrefix, seqNum)

	var bookingID int
	err = tx.QueryRow(ctx, `
		INSERT INTO bookings (booking_ref, user_id, court_id, venue_id, slot_id, status, sports_id, is_payment_enabled, payment_status, amount)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
		RETURNING id`,
		bookingRef,
		req.CusUserId,
		nullIfZero(courtId),
		req.VenueId,
		nullIfZero(req.SlotId),
		initialStatus,
		nullIfZero(req.Sports_id),
		isPaymentEnabled,
		paymentStatus,
		req.Amount,
	).Scan(&bookingID)

	if err != nil {
		c.JSON(500, gin.H{"success": false, "message": err.Error()})
		return
	}

	_, err = tx.Exec(ctx, `
		INSERT INTO bookings_mapping (booking_id, start_time, end_time, slot_id, sports_id, court_id)
		VALUES ($1, $2, $3, $4, $5, $6)`,
		bookingID,
		req.StartTime,
		req.EndTime,
		nullIfZero(req.SlotId),
		nullIfZero(req.Sports_id),
		nullIfZero(courtId),
	)

	if err != nil {
		c.JSON(500, gin.H{"success": false, "message": err.Error()})
		return
	}

	if err := tx.Commit(ctx); err != nil {
		c.JSON(500, gin.H{"success": false, "message": err.Error()})
		return
	}

	// Fetch venue name and sport name for response/notifications
	var venueName string
	_ = dal.DB.QueryRow(ctx, "SELECT name FROM venues WHERE id = $1", req.VenueId).Scan(&venueName)
	var sportName string
	if req.Sports_id != "" && req.Sports_id != "0" {
		_ = dal.DB.QueryRow(ctx, "SELECT name FROM sports WHERE id = $1", req.Sports_id).Scan(&sportName)
	}

	// --- Case 1: Payment DISABLED → Directly confirmed, send notifications ---
	if !isPaymentEnabled {
		TriggerBookingNotifications(BookingNotifyData{
			BookingID:  bookingID,
			BookingRef: bookingRef,
			UserID:     req.CusUserId,
			VenueName:  venueName,
			SportName:  sportName,
			Date:       req.Date,
			StartTime:  req.StartTime,
			EndTime:    req.EndTime,
			Amount:     req.Amount,
		})

		// Save to notifications table
		InsertNotification(ctx, req.CusUserId, "booking_confirmed",
			"Booking Confirmed!",
			fmt.Sprintf("Your booking at %s on %s (%s - %s) is confirmed. Ref: %s",
				venueName, req.Date, req.StartTime, req.EndTime, bookingRef),
			map[string]interface{}{
				"booking_id":  bookingID,
				"booking_ref": bookingRef,
				"venue_name":  venueName,
				"sport":       sportName,
				"date":        req.Date,
				"start_time":  req.StartTime,
				"end_time":    req.EndTime,
				"amount":      req.Amount,
			},
		)

		c.JSON(200, gin.H{
			"success":            true,
			"message":            "Booking Confirmed",
			"booking_id":         bookingID,
			"booking_ref":        bookingRef,
			"is_payment_enabled": false,
			"status":             "CONFIRMED",
		})
		return
	}

	// --- Case 2: Payment ENABLED → Return payment URL, await callback ---
	// Generate payment URL (placeholder — replace with actual gateway integration)
	paymentUrl := fmt.Sprintf("/payment?booking_id=%d&amount=%s", bookingID, req.Amount)

	// Save payment URL
	_, _ = dal.DB.Exec(ctx, `UPDATE bookings SET payment_url = $1 WHERE id = $2`, paymentUrl, bookingID)

	c.JSON(200, gin.H{
		"success":            true,
		"message":            "Proceed to payment",
		"booking_id":         bookingID,
		"booking_ref":        bookingRef,
		"is_payment_enabled": true,
		"payment_url":        paymentUrl,
		"status":             "PENDING",
	})
}

// --- Payment Success Callback ---
type PaymentSuccessRequest struct {
	BookingID     int    `json:"booking_id" binding:"required"`
	TransactionID string `json:"transaction_id" binding:"required"`
	Status        string `json:"status" binding:"required"` // "Success" or "Failed"
}

func Payment_Callback(c *gin.Context) {
	ctx := c.Request.Context()

	var req PaymentSuccessRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid Request"})
		return
	}

	// Idempotency check — skip if already processed
	var currentPaymentStatus string
	err := dal.DB.QueryRow(ctx,
		"SELECT COALESCE(payment_status, 'PENDING') FROM bookings WHERE id = $1",
		req.BookingID,
	).Scan(&currentPaymentStatus)

	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "Booking not found"})
		return
	}

	if currentPaymentStatus == "SUCCESS" {
		c.JSON(http.StatusOK, gin.H{"success": true, "message": "Already processed"})
		return
	}

	if req.Status == "Success" {
		// Payment succeeded → Confirm booking + trigger notifications
		_, err := dal.ExecNonQuery(ctx, `
			UPDATE bookings
			SET status = 'CONFIRMED', payment_status = 'SUCCESS',
			    transaction_id = $1, payment_at = CURRENT_TIMESTAMP
			WHERE id = $2 AND payment_status = 'PENDING'`,
			req.TransactionID, req.BookingID,
		)
		if err != nil {
			log.Printf("[PAYMENT] Error confirming booking %d: %v", req.BookingID, err)
			c.JSON(500, gin.H{"success": false, "message": "Database error"})
			return
		}

		// Fetch booking details for notification
		var userID, venueName, date, startTime, endTime string
		_ = dal.DB.QueryRow(ctx, `
			SELECT b.user_id::text, COALESCE(v.name, ''), COALESCE(m.start_time, ''), COALESCE(m.end_time, '')
			FROM bookings b
			LEFT JOIN venues v ON v.id = b.venue_id
			LEFT JOIN bookings_mapping m ON m.booking_id = b.id
			WHERE b.id = $1`,
			req.BookingID,
		).Scan(&userID, &venueName, &startTime, &endTime)

		// Use booking date from the bookings table
		_ = dal.DB.QueryRow(ctx,
			"SELECT COALESCE(TO_CHAR(booked_at, 'YYYY-MM-DD'), '') FROM bookings WHERE id = $1",
			req.BookingID,
		).Scan(&date)

		var pBookingRef, pSportName, pAmount string
		_ = dal.DB.QueryRow(ctx, `SELECT COALESCE(booking_ref,''), COALESCE(amount::text,'0') FROM bookings WHERE id = $1`, req.BookingID).Scan(&pBookingRef, &pAmount)
		var pSportID int
		if err := dal.DB.QueryRow(ctx, `SELECT COALESCE(sports_id,0) FROM bookings WHERE id = $1`, req.BookingID).Scan(&pSportID); err == nil && pSportID > 0 {
			_ = dal.DB.QueryRow(ctx, `SELECT name FROM sports WHERE id = $1`, pSportID).Scan(&pSportName)
		}

		TriggerBookingNotifications(BookingNotifyData{
			BookingID:  req.BookingID,
			BookingRef: pBookingRef,
			UserID:     userID,
			VenueName:  venueName,
			SportName:  pSportName,
			Date:       date,
			StartTime:  startTime,
			EndTime:    endTime,
			Amount:     pAmount,
		})

		// Save to notifications table
		InsertNotification(ctx, userID, "booking_confirmed",
			"Booking Confirmed!",
			fmt.Sprintf("Your booking at %s on %s (%s - %s) is confirmed. Ref: %s",
				venueName, date, startTime, endTime, pBookingRef),
			map[string]interface{}{
				"booking_id":  req.BookingID,
				"booking_ref": pBookingRef,
				"venue_name":  venueName,
				"sport":       pSportName,
				"date":        date,
				"start_time":  startTime,
				"end_time":    endTime,
				"amount":      pAmount,
			},
		)

		c.JSON(200, gin.H{
			"success": true,
			"message": "Payment successful, booking confirmed",
		})
	} else {
		// Payment failed → Mark as failed, NO notification
		_, _ = dal.ExecNonQuery(ctx, `
			UPDATE bookings
			SET payment_status = 'FAILED', transaction_id = $1
			WHERE id = $2 AND payment_status = 'PENDING'`,
			req.TransactionID, req.BookingID,
		)

		c.JSON(200, gin.H{
			"success": false,
			"message": "Payment failed, booking not confirmed",
		})
	}
}

func GetBookingQRData(c *gin.Context) {
	var req BookingQRRequest
	ctx := c.Request.Context()

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid Request",
		})
		return
	}

	query := `
		SELECT b.id, v.name as venue_name, m.start_time, m.end_time, b.status
		FROM bookings b
		JOIN venues v ON b.venue_id = v.id
		JOIN bookings_mapping m ON b.id = m.booking_id
		WHERE b.id = $1 AND b.status = 'PENDING'
        AND EXTRACT(HOUR FROM (m.end_time::time)) >= EXTRACT(HOUR FROM current_timestamp);
	`

	rows, err := dal.Query(ctx, query, req.BookingID)
	if err != nil {
		log.Printf("Query error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Database error",
		})
		return
	}
	defer rows.Close()

	var booking BookingQRDB
	if rows.Next() {
		//var startStr, endStr string

		if err := rows.Scan(
			&booking.ID,
			&booking.VenueName,
			&booking.StartTime,
			&booking.EndTime,
			&booking.Status,
		); err != nil {
			log.Printf("Scan error: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{
				"success": false,
				"message": "Scan error",
			})
			return
		}
		updatequery := `update bookings set status='CHECKED-IN' where id in ($1) and status = 'PENDING'`
		row, err := dal.ExecNonQuery(ctx, updatequery, booking.ID)
		if err != nil || row == 0 {
			c.JSON(200, gin.H{
				"success":    true,
				"message":    "Status Update unsuccessful",
				"booking_id": booking,
			})
		} else {
			c.JSON(200, gin.H{
				"success": true,
				"message": "Status Update successfully",
				"data":    booking,
			})
		}
	} else {
		c.JSON(http.StatusNotFound, gin.H{
			"success": false,
			"message": "Booking not found",
		})
		return
	}

}

// 1. Define the Data Structures
type BookingHistoryRequest struct {
	UserID   string `json:"user_id" binding:"required"`
	UserType string `json:"user_type"` // admin, owner, vendor, manager, user
}

type BookingHistoryResponse struct {
	ID         int     `json:"id"`
	VenueName  string  `json:"venue_name"`
	StartTime  string  `json:"start_time"`
	EndTime    string  `json:"end_time"`
	Status     string  `json:"status"`
	Price      float64 `json:"price"`
	BookingRef string  `json:"booking_ref"`
	VenueImage string  `json:"venue_image"`
	UserName   string  `json:"user_name"`
	BookedAt   string  `json:"booked_at"`
}

// Role-based booking history handler
func GetMyBookingHistory(c *gin.Context) {
	var req BookingHistoryRequest
	ctx := c.Request.Context()

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid Request"})
		return
	}

	var query string
	var args []interface{}

	userType := req.UserType
	if userType == "" {
		userType = "user"
	}

	baseSelect := `
		SELECT
			b.id,
			v.name as venue_name,
			COALESCE(m.start_time, '') as start_time,
			COALESCE(m.end_time, '') as end_time,
			b.status,
			COALESCE(b.amount, 0) as price,
			COALESCE(b.booking_ref, 'BK-' || b.id) as booking_ref,
			COALESCE(v.image_url, '') as venue_image,
			COALESCE(u.username, '') as user_name,
			COALESCE(TO_CHAR(b.booked_at, 'YYYY-MM-DD HH24:MI'), '') as booked_at
		FROM bookings b
		JOIN venues v ON b.venue_id = v.id
		LEFT JOIN bookings_mapping m ON b.id = m.booking_id
		LEFT JOIN users u ON b.user_id = u.id
	`

	switch userType {
	case "admin":
		// Admin: all bookings across all venues
		query = baseSelect + `
			ORDER BY b.booked_at DESC
		`
	case "owner", "vendor", "manager":
		// Owner/Vendor/Manager: bookings under their mapped venues
		query = baseSelect + `
			WHERE b.venue_id IN (
				SELECT venue_id FROM user_venue_mapping
				WHERE user_id = $1 AND is_active = TRUE
			)
			ORDER BY b.booked_at DESC
		`
		args = append(args, req.UserID)
	default:
		// User: only their own bookings
		query = baseSelect + `
			WHERE b.user_id = $1
			ORDER BY b.booked_at DESC
		`
		args = append(args, req.UserID)
	}

	rows, err := dal.Query(ctx, query, args...)
	if err != nil {
		log.Printf("Query error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Database error"})
		return
	}
	defer rows.Close()

	var history []BookingHistoryResponse
	for rows.Next() {
		var b BookingHistoryResponse
		if err := rows.Scan(
			&b.ID,
			&b.VenueName,
			&b.StartTime,
			&b.EndTime,
			&b.Status,
			&b.Price,
			&b.BookingRef,
			&b.VenueImage,
			&b.UserName,
			&b.BookedAt,
		); err != nil {
			log.Printf("Scan error: %v", err)
			continue
		}
		history = append(history, b)
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    history,
	})
}

type TurfAnalyticsRequest struct {
	User_id   string `json:"user_id"`
	User_type string `json:"user_type"`
}

func GetTurfAnalytics(c *gin.Context) {
	var req TurfAnalyticsRequest
	ctx := c.Request.Context()

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid Request"})
		return
	}

	var stats Models.AnalyticsResponse
	isAdmin := req.User_type == "admin"

	// 1️⃣ Total Bookings, Revenue, and Occupancy
	var statsQuery string
	if isAdmin {
		statsQuery = `
			SELECT
				COUNT(b.id) as total_bookings,
				COALESCE(SUM(b.amount), 0) as total_revenue,
				COALESCE((
					SELECT ROUND(
						(COUNT(CASE WHEN t.is_booked = true THEN 1 END)::numeric /
						NULLIF(COUNT(*), 0)::numeric) * 100, 1
					)
					FROM time_slots t
				), 0) as occupancy
			FROM bookings b;
		`
	} else {
		statsQuery = `
			SELECT
				COUNT(b.id) as total_bookings,
				COALESCE(SUM(b.amount), 0) as total_revenue,
				COALESCE((
					SELECT ROUND(
						(COUNT(CASE WHEN t.is_booked = true THEN 1 END)::numeric /
						NULLIF(COUNT(*), 0)::numeric) * 100, 1
					)
					FROM time_slots t
					WHERE t.venue_id IN (
						SELECT venue_id FROM user_venue_mapping
						WHERE user_id = $1 AND is_active = true
					)
				), 0) as occupancy
			FROM bookings b
			WHERE b.venue_id IN (
				SELECT venue_id FROM user_venue_mapping
				WHERE user_id = $1 AND is_active = true
			);
		`
	}

	var err error
	if isAdmin {
		err = dal.QueryRow(ctx, statsQuery).Scan(
			&stats.TotalBookings,
			&stats.TotalRevenue,
			&stats.Occupancy,
		)
	} else {
		err = dal.QueryRow(ctx, statsQuery, req.User_id).Scan(
			&stats.TotalBookings,
			&stats.TotalRevenue,
			&stats.Occupancy,
		)
	}

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// 2️⃣ Weekly Trend (Last 7 Days)
	var trendQuery string
	if isAdmin {
		trendQuery = `
		SELECT
			TO_CHAR(d.day, 'Dy') AS day_name,
			COUNT(b.id) AS total_bookings
		FROM (
			SELECT generate_series(
				CURRENT_DATE - INTERVAL '6 days',
				CURRENT_DATE,
				'1 day'
			)::date AS day
		) d
		LEFT JOIN bookings b ON DATE(b.booked_at) = d.day
		GROUP BY d.day
		ORDER BY d.day ASC;
		`
	} else {
		trendQuery = `
		SELECT
			TO_CHAR(d.day, 'Dy') AS day_name,
			COUNT(b.id) AS total_bookings
		FROM (
			SELECT generate_series(
				CURRENT_DATE - INTERVAL '6 days',
				CURRENT_DATE,
				'1 day'
			)::date AS day
		) d
		LEFT JOIN bookings b
			ON DATE(b.booked_at) = d.day
			AND b.venue_id IN (
				SELECT venue_id FROM user_venue_mapping
				WHERE user_id = $1 AND is_active = true
			)
		GROUP BY d.day
		ORDER BY d.day ASC;
		`
	}

	var rows pgx.Rows
	if isAdmin {
		rows, err = dal.Query(ctx, trendQuery)
	} else {
		rows, err = dal.Query(ctx, trendQuery, req.User_id)
	}
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer rows.Close()

	for rows.Next() {
		var t Models.WeeklyTrend
		if err := rows.Scan(&t.Day, &t.Count); err != nil {
			continue
		}
		stats.WeeklyTrend = append(stats.WeeklyTrend, t)
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    stats,
	})
}

type RecentBookingsAdminRequest struct {
	User_id   string `json:"user_id"`
	User_type string `json:"user_type"`
	Limit     int    `json:"limit"`
}

func GetRecentBookingsAdmin(c *gin.Context) {
	var req RecentBookingsAdminRequest
	ctx := c.Request.Context()

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid Request"})
		return
	}

	var query string
	var rows pgx.Rows
	var err error

	if req.User_type == "admin" || req.User_type == "" {
		// Admin: fetch all bookings
		query = `
			SELECT
				b.id,
				c.name as court_name,
				u.username as user_name,
				COALESCE(b.booking_ref, 'BK-' || b.id) as booking_ref,
				COALESCE(ts.price, 0) as price,
				b.status,
				COALESCE(m.start_time, '') as start_time
			FROM bookings b
			JOIN users u ON b.user_id = u.id
			JOIN courts c ON b.court_id = c.id
			LEFT JOIN time_slots ts ON b.slot_id = ts.id
			LEFT JOIN bookings_mapping m ON b.id = m.booking_id
			ORDER BY b.booked_at DESC
			LIMIT $1
		`
		rows, err = dal.Query(ctx, query, req.Limit)
	} else {
		// Owner/Vendor/Manager: fetch only their venue bookings
		query = `
			SELECT
				b.id,
				c.name as court_name,
				u.username as user_name,
				COALESCE(b.booking_ref, 'BK-' || b.id) as booking_ref,
				COALESCE(ts.price, 0) as price,
				b.status,
				COALESCE(m.start_time, '') as start_time
			FROM bookings b
			JOIN users u ON b.user_id = u.id
			JOIN courts c ON b.court_id = c.id
			LEFT JOIN time_slots ts ON b.slot_id = ts.id
			LEFT JOIN bookings_mapping m ON b.id = m.booking_id
			WHERE b.venue_id IN (
				SELECT venue_id FROM user_venue_mapping
				WHERE user_id = $1 AND is_active = true
			)
			ORDER BY b.booked_at DESC
			LIMIT $2
		`
		rows, err = dal.Query(ctx, query, req.User_id, req.Limit)
	}
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Database error"})
		return
	}
	defer rows.Close()

	var bookings []Models.RecentBookingResponse
	for rows.Next() {
		var rb Models.RecentBookingResponse
		if err := rows.Scan(
			&rb.ID,
			&rb.CourtName,
			&rb.UserName,
			&rb.BookingRef,
			&rb.Price,
			&rb.Status,
			&rb.StartTime,
		); err != nil {
			continue
		}
		bookings = append(bookings, rb)
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    bookings,
	})
}
