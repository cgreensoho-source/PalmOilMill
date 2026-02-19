package controllers

import (
	"fmt"
	"path/filepath"
	"sampling/models"
	"sampling/repository"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
)

type SampleController struct {
	sampleRepo *repository.SampleRepository
	imageRepo  *repository.ImageRepository
}

func NewSampleController() *SampleController {
	return &SampleController{
		sampleRepo: repository.NewSampleRepository(),
		imageRepo:  repository.NewImageRepository(),
	}
}

// CreateSampleRequest represents create sample request body
type CreateSampleRequest struct {
	UserID     uint   `json:"user_id"`
	StationID  uint   `json:"station_id"`
	SampleName string `json:"sample_name"`
	Condition  string `json:"condition"` // Catatan kondisi
}

// CreateSampleResponse represents create sample response
type CreateSampleResponse struct {
	SampleID uint   `json:"sample_id"`
	Message  string `json:"message"`
}

// CreateSample creates a new sample with multiple images (foto petugas dari kamera)
func (ctrl *SampleController) CreateSample(c *fiber.Ctx) error {
	// Parse multipart form data
	form, err := c.MultipartForm()
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Failed to parse multipart form"})
	}

	// Extract form values
	userIDStr := form.Value["user_id"]
	stationIDStr := form.Value["station_id"]
	sampleName := form.Value["sample_name"]

	if len(userIDStr) == 0 || len(stationIDStr) == 0 || len(sampleName) == 0 {
		return c.Status(400).JSON(fiber.Map{"error": "Missing required fields: user_id, station_id, sample_name"})
	}

	// Convert strings to uint
	var userID, stationID uint
	fmt.Sscanf(userIDStr[0], "%d", &userID)
	fmt.Sscanf(stationIDStr[0], "%d", &stationID)

	// Create sample record
	sample := models.Sample{
		UserID:     userID,
		StationID:  stationID,
		SampleName: sampleName[0],
		CreatedAt:  time.Now(),
	}

	if err := ctrl.sampleRepo.CreateSample(&sample); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to create sample"})
	}

	// Handle multiple file uploads (images from camera)
	// form already parsed above

	files := form.File["images"]
	for _, file := range files {
		// Generate unique filename
		ext := filepath.Ext(file.Filename)
		filename := fmt.Sprintf("%s%s", uuid.New().String(), ext)
		filepath := filepath.Join("upload", filename)

		// Save file to upload directory
		if err := c.SaveFile(file, filepath); err != nil {
			return c.Status(500).JSON(fiber.Map{"error": "Failed to save image"})
		}

		// Create image record
		image := models.Image{
			ImagePath: filepath,
			UserID:    userID,
			SampleID:  sample.SampleID,
			CreatedAt: time.Now(),
		}

		if err := ctrl.imageRepo.CreateImage(&image); err != nil {
			return c.Status(500).JSON(fiber.Map{"error": "Failed to save image record"})
		}
	}

	response := CreateSampleResponse{
		SampleID: sample.SampleID,
		Message:  "Sample created successfully with images",
	}

	return c.JSON(response)
}

// GetAllSamples returns all samples with optional filters
func (ctrl *SampleController) GetAllSamples(c *fiber.Ctx) error {
	// Parse query parameters
	var userID, stationID *uint
	var startDate, endDate *string

	if userIDStr := c.Query("user_id"); userIDStr != "" {
		id := new(uint)
		fmt.Sscanf(userIDStr, "%d", id)
		userID = id
	}

	if stationIDStr := c.Query("station_id"); stationIDStr != "" {
		id := new(uint)
		fmt.Sscanf(stationIDStr, "%d", id)
		stationID = id
	}

	if start := c.Query("start_date"); start != "" {
		startDate = &start
	}

	if end := c.Query("end_date"); end != "" {
		endDate = &end
	}

	samples, err := ctrl.sampleRepo.GetAllSamples(userID, stationID, startDate, endDate)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to retrieve samples"})
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    samples,
		"total":   len(samples),
	})
}

// GetSampleDetail returns a single sample with images
func (ctrl *SampleController) GetSampleDetail(c *fiber.Ctx) error {
	sampleID, err := c.ParamsInt("id")
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid sample ID"})
	}

	sample, err := ctrl.sampleRepo.GetSampleByID(uint(sampleID))
	if err != nil {
		return c.Status(404).JSON(fiber.Map{"error": "Sample not found"})
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    sample,
	})
}

// GetImage returns an image file
func (ctrl *SampleController) GetImage(c *fiber.Ctx) error {
	imageID, err := c.ParamsInt("id")
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid image ID"})
	}

	image, err := ctrl.imageRepo.GetImageByID(uint(imageID))
	if err != nil {
		return c.Status(404).JSON(fiber.Map{"error": "Image not found"})
	}

	// Serve the image file
	return c.SendFile(image.ImagePath)
}
