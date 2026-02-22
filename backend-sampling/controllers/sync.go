package controllers

import (
	"sampling/models"
	"sampling/repository"

	"github.com/gofiber/fiber/v2"
)

type SyncController struct {
	sampleRepo *repository.SampleRepository
	imageRepo  *repository.ImageRepository
}

func NewSyncController() *SyncController {
	return &SyncController{
		sampleRepo: repository.NewSampleRepository(),
		imageRepo:  repository.NewImageRepository(),
	}
}

// SyncDataRequest represents sync data request body
type SyncDataRequest struct {
	Samples []SyncSampleRequest `json:"samples"`
}

// SyncSampleRequest represents sample data for sync
type SyncSampleRequest struct {
	UserID     uint               `json:"user_id"`
	StationID  uint               `json:"station_id"`
	SampleName string             `json:"sample_name"`
	Condition  string             `json:"condition"`
	Images     []SyncImageRequest `json:"images"`
}

// SyncImageRequest represents image data for sync
type SyncImageRequest struct {
	ImagePath string `json:"image_path"`
	UserID    uint   `json:"user_id"`
}

// SyncDataResponse represents sync response
type SyncDataResponse struct {
	Message       string `json:"message"`
	SyncedSamples int    `json:"synced_samples"`
	SyncedImages  int    `json:"synced_images"`
}

// SyncData handles offline to online data synchronization
func (ctrl *SyncController) SyncData(c *fiber.Ctx) error {
	var req SyncDataRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid request body"})
	}

	syncedSamples := 0
	syncedImages := 0

	for _, sampleReq := range req.Samples {
		// Create sample
		sample := models.Sample{
			UserID:     sampleReq.UserID,
			StationID:  sampleReq.StationID,
			SampleName: sampleReq.SampleName,
		}

		if err := ctrl.sampleRepo.CreateSample(&sample); err != nil {
			return c.Status(500).JSON(fiber.Map{"error": "Failed to sync sample"})
		}

		syncedSamples++

		// Create images for this sample
		for _, imageReq := range sampleReq.Images {
			image := models.Image{
				ImagePath: imageReq.ImagePath,
				UserID:    imageReq.UserID,
				SampleID:  sample.SampleID,
			}

			if err := ctrl.imageRepo.CreateImage(&image); err != nil {
				return c.Status(500).JSON(fiber.Map{"error": "Failed to sync image"})
			}

			syncedImages++
		}
	}

	response := SyncDataResponse{
		Message:       "Data synchronized successfully",
		SyncedSamples: syncedSamples,
		SyncedImages:  syncedImages,
	}

	return c.JSON(response)
}
