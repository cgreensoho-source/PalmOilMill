package controllers

import (
	"fmt"
	"math"
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

// GPSValidationResponse represents GPS validation response
type GPSValidationResponse struct {
	Valid             bool      `json:"valid"`
	Station           fiber.Map `json:"station"`
	Distance          float64   `json:"distance"`
	Message           string    `json:"message"`
	StationLat        float64   `json:"station_lat"`
	StationLng        float64   `json:"station_lng"`
	UserLat           float64   `json:"user_lat"`
	UserLng           float64   `json:"user_lng"`
	RecommendedRadius float64   `json:"recommended_radius"`
}

// ScanQR validates QR code and records scan with auto-generated timestamp and coordinate
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
