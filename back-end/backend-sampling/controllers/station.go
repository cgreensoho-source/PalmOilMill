package controllers

import (
	"fmt"
	"math"
	"sampling/models"
	"sampling/repository"
	"strconv"
	"strings"

	"github.com/gofiber/fiber/v2"
)

type StationController struct {
	stationRepo *repository.StationRepository
}

func NewStationController() *StationController {
	return &StationController{
		stationRepo: repository.NewStationRepository(),
	}
}

// GetStations returns list of all stations for QR validation
// GetStations godoc
// @Summary      Ambil Semua Data Stasiun
// @Description  Mengambil daftar lengkap stasiun untuk sinkronisasi data mobile app.
// @Tags         stations
// @Produce      json
// @Success      200  {object}  map[string]interface{}
// @Router       /stations [get]
func (ctrl *StationController) GetStations(c *fiber.Ctx) error {
	stations, err := ctrl.stationRepo.GetAllStations()
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to retrieve stations"})
	}

	return c.JSON(fiber.Map{"stations": stations})
}

// ScanRequest represents scan QR request body
type ScanRequest struct {
	StationID  uint   `json:"station_id"`
	Coordinate string `json:"coordinate"`
}

// ScanResponse represents scan response
type ScanResponse struct {
	Message   string `json:"message"`
	StationID uint   `json:"station_id"`
	UserID    uint   `json:"user_id"`
}

// GPSValidationRequest represents GPS validation request
type GPSValidationRequest struct {
	QRData      string  `json:"qr_data"`
	UserLat     float64 `json:"user_lat"`
	UserLng     float64 `json:"user_lng"`
	MaxDistance float64 `json:"max_distance,omitempty"` // Optional, default 50m
}

// // GPSValidationResponse represents GPS validation response
// type GPSValidationResponse struct {
// 	Valid             bool      `json:"valid"`
// 	Station           fiber.Map `json:"station"`
// 	Distance          float64   `json:"distance"`
// 	Message           string    `json:"message"`
// 	StationLat        float64   `json:"station_lat"`
// 	StationLng        float64   `json:"station_lng"`
// 	UserLat           float64   `json:"user_lat"`
// 	UserLng           float64   `json:"user_lng"`
// 	RecommendedRadius float64   `json:"recommended_radius"`
// }

// Ganti yang ini:
type GPSValidationResponse struct {
	Valid             bool                   `json:"valid"`
	Station           map[string]interface{} `json:"station"` // Ganti dari fiber.Map ke ini
	Distance          float64                `json:"distance"`
	Message           string                 `json:"message"`
	StationLat        float64                `json:"station_lat"`
	StationLng        float64                `json:"station_lng"`
	UserLat           float64                `json:"user_lat"`
	UserLng           float64                `json:"user_lng"`
	RecommendedRadius float64                `json:"recommended_radius"`
}

// ScanQR validates QR code and records scan with auto-generated timestamp and coordinate
// ScanQR godoc
// @Summary      Validasi Scan QR Stasiun
// @Description  Memproses data hasil scan QR stasiun untuk pencatatan log petugas.
// @Tags         stations
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        scan  body      ScanRequest  true  "Scan Data"
// @Success      200   {object}  ScanResponse
// @Failure      404   {object}  map[string]string "Station not found"
// @Router       /stations/scan [post]
func (ctrl *StationController) ScanQR(c *fiber.Ctx) error {
	var req ScanRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid request body"})
	}

	// Validate required fields
	if req.StationID == 0 {
		return c.Status(400).JSON(fiber.Map{"error": "Station ID is required"})
	}

	// Validate station exists
	_, err := ctrl.stationRepo.GetStationByID(req.StationID)
	if err != nil {
		return c.Status(404).JSON(fiber.Map{"error": "Station not found"})
	}

	// Get user ID from JWT token
	userID := c.Locals("user_id").(float64)

	response := ScanResponse{
		Message:   "QR scan successful",
		StationID: req.StationID,
		UserID:    uint(userID),
	}

	return c.JSON(response)
}

// ValidateGPS validates user location against station coordinates
// ValidateGPS godoc
// @Summary      Validasi Lokasi GPS (Anti-Fraud)
// @Description  Memvalidasi jarak antara koordinat petugas (GPS HP) dengan koordinat stasiun asli menggunakan rumus Haversine. Maksimal toleransi 50 meter.
// @Tags         stations
// @Accept       json
// @Produce      json
// @Param        gps   body      GPSValidationRequest  true  "GPS & QR Data"
// @Success      200   {object}  GPSValidationResponse
// @Failure      400   {object}  map[string]string "Invalid format"
// @Router       /stations/validate-gps [post]
func (ctrl *StationController) ValidateGPS(c *fiber.Ctx) error {
	var req GPSValidationRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid request body"})
	}

	// Set default max distance if not provided
	if req.MaxDistance == 0 {
		req.MaxDistance = 50.0 // 50 meters default
	}

	// Parse QR data
	if !strings.HasPrefix(req.QRData, "STATION:") {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid QR data format"})
	}

	qrParts := strings.Split(strings.TrimPrefix(req.QRData, "STATION:"), "|")
	if len(qrParts) < 3 {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid QR data structure"})
	}

	stationIDStr := qrParts[0]
	stationName := qrParts[1]
	stationCoord := qrParts[2]

	// Parse station coordinates
	coordParts := strings.Split(stationCoord, ",")
	if len(coordParts) != 2 {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid station coordinates"})
	}

	stationLat, err := strconv.ParseFloat(coordParts[0], 64)
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid station latitude"})
	}

	stationLng, err := strconv.ParseFloat(coordParts[1], 64)
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid station longitude"})
	}

	// Calculate distance using Haversine formula
	distance := calculateDistance(req.UserLat, req.UserLng, stationLat, stationLng)

	// Validate location
	isValid := distance <= req.MaxDistance

	// Prepare response
	message := ""
	if isValid {
		message = fmt.Sprintf("Lokasi valid! Jarak dari stasiun: %.1f meter", distance)
	} else {
		message = fmt.Sprintf("Lokasi tidak valid. Jarak dari stasiun: %.1f meter (max: %.0f meter)", distance, req.MaxDistance)
	}

	response := GPSValidationResponse{
		Valid: isValid,
		Station: fiber.Map{
			"id":         stationIDStr,
			"name":       stationName,
			"coordinate": stationCoord,
		},
		Distance:          distance,
		Message:           message,
		StationLat:        stationLat,
		StationLng:        stationLng,
		UserLat:           req.UserLat,
		UserLng:           req.UserLng,
		RecommendedRadius: req.MaxDistance,
	}

	return c.JSON(response)
}

// Helper functions for GPS calculations
func calculateDistance(lat1, lng1, lat2, lng2 float64) float64 {
	const R = 6371e3 // Earth's radius in meters

	// Convert to radians
	φ1 := lat1 * math.Pi / 180
	φ2 := lat2 * math.Pi / 180
	Δφ := (lat2 - lat1) * math.Pi / 180
	Δλ := (lng2 - lng1) * math.Pi / 180

	a := math.Sin(Δφ/2)*math.Sin(Δφ/2) + math.Cos(φ1)*math.Cos(φ2)*math.Sin(Δλ/2)*math.Sin(Δλ/2)
	c := 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))

	return R * c // Distance in meters
}

// CreateStationRequest defines the input for creating a new station
type CreateStationRequest struct {
	StationName string `json:"station_name" validate:"required"`
	Coordinate  string `json:"coordinate" validate:"required"` // Format: "lat,lng"
}

// CreateStation godoc
// @Summary      Tambah Stasiun Baru (Admin Only)
// @Description  Memasukkan data stasiun baru. Koordinat harus dikirim dari GPS perangkat FE agar akurat.
// @Tags         stations
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        station  body      CreateStationRequest  true  "Data Stasiun"
// @Success      201      {object}  models.Station
// @Failure      403      {object}  map[string]string "Forbidden: Admin only"
// @Router       /stations [post]
func (ctrl *StationController) CreateStation(c *fiber.Ctx) error {
	// 1. Check Access (Hanya Admin)
	role := c.Locals("role")
	if role != "admin" {
		return c.Status(403).JSON(fiber.Map{"error": "Access denied: Admin only"})
	}

	var req CreateStationRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid request body"})
	}

	// 2. Validasi input sederhana
	if req.StationName == "" || req.Coordinate == "" {
		return c.Status(400).JSON(fiber.Map{"error": "Station name and coordinate are required"})
	}

	// 3. Mapping ke Model
	station := models.Station{
		StationName: req.StationName,
		Coordinate:  req.Coordinate,
	}

	// 4. Simpan ke Database
	if err := ctrl.stationRepo.CreateStation(&station); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to save station"})
	}

	return c.Status(201).JSON(fiber.Map{
		"message": "Station created successfully",
		"data":    station,
	})
}
