package controllers

import (
	"fmt"
	"sampling/repository"
	"strconv"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/skip2/go-qrcode"
)

type QRController struct {
	stationRepo *repository.StationRepository
}

func NewQRController() *QRController {
	return &QRController{
		stationRepo: repository.NewStationRepository(),
	}
}

// GenerateQR generates QR code for a specific station
func (ctrl *QRController) GenerateQR(c *fiber.Ctx) error {
	stationIDStr := c.Params("id")

	// Parse station ID to uint
	stationID, err := strconv.ParseUint(stationIDStr, 10, 32)
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid station ID"})
	}

	// Validate station exists
	station, err := ctrl.stationRepo.GetStationByID(uint(stationID))
	if err != nil {
		return c.Status(404).JSON(fiber.Map{"error": "Station not found"})
	}

	// Create QR code data with detailed information
	// Format: STATION:{id}|{name}|{coordinate}|{timestamp}
	timestamp := time.Now().Format("2006-01-02 15:04:05")
	qrData := fmt.Sprintf("STATION:%s|%s|%s|%s",
		stationIDStr,
		station.StationName,
		station.Coordinate,
		timestamp)

	// Generate QR code as PNG with High quality for better scanning
	qrCode, err := qrcode.Encode(qrData, qrcode.High, 512)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to generate QR code"})
	}

	// Set content type and return QR code image
	c.Set("Content-Type", "image/png")
	return c.Send(qrCode)
}

// GetStationWithQR returns station data with QR code URL
func (ctrl *QRController) GetStationWithQR(c *fiber.Ctx) error {
	stationIDStr := c.Params("id")

	// Parse station ID to uint
	stationID, err := strconv.ParseUint(stationIDStr, 10, 32)
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid station ID"})
	}

	station, err := ctrl.stationRepo.GetStationByID(uint(stationID))
	if err != nil {
		return c.Status(404).JSON(fiber.Map{"error": "Station not found"})
	}

	// Add QR code URL to response
	response := fiber.Map{
		"station":           station,
		"qr_url":            c.BaseURL() + "/api/v1/stations/" + stationIDStr + "/qr",
		"qr_data_format":    "STATION:{id}|{name}|{coordinate}|{timestamp}",
		"scan_instructions": "Scan QR code dengan mobile app untuk auto-fill station data",
	}

	return c.JSON(response)
}

// GetQRData returns the QR code data as text for debugging/testing
func (ctrl *QRController) GetQRData(c *fiber.Ctx) error {
	stationIDStr := c.Params("id")

	// Parse station ID to uint
	stationID, err := strconv.ParseUint(stationIDStr, 10, 32)
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid station ID"})
	}

	// Validate station exists
	station, err := ctrl.stationRepo.GetStationByID(uint(stationID))
	if err != nil {
		return c.Status(404).JSON(fiber.Map{"error": "Station not found"})
	}

	// Create QR code data (same as in GenerateQR)
	timestamp := time.Now().Format("2006-01-02 15:04:05")
	qrData := fmt.Sprintf("STATION:%s|%s|%s|%s",
		stationIDStr,
		station.StationName,
		station.Coordinate,
		timestamp)

	// Return the data as JSON for testing
	response := fiber.Map{
		"station_id":   stationIDStr,
		"station_name": station.StationName,
		"coordinate":   station.Coordinate,
		"timestamp":    timestamp,
		"qr_data":      qrData,
		"data_format":  "STATION:{id}|{name}|{coordinate}|{timestamp}",
		"mobile_app_flow": fiber.Map{
			"scan_qr":           "Scan QR code dengan mobile app",
			"parse_data":        "Extract station info dari QR data",
			"get_gps":           "Dapatkan lokasi real-time user dengan GPS",
			"validate_location": "Bandingkan GPS user dengan koordinat stasiun",
			"proximity_check":   "Pastikan user berada dalam radius 50m dari stasiun",
			"auto_fill":         "Auto-fill form sampling dengan data stasiun",
		},
		"gps_validation": fiber.Map{
			"station_coordinate": station.Coordinate,
			"recommended_radius": "50 meters",
			"purpose":            "Memastikan sampling dilakukan di lokasi yang benar",
		},
		"test_scan": "Gunakan QR scanner app untuk scan gambar PNG dari /qr endpoint",
	}

	return c.JSON(response)
}
