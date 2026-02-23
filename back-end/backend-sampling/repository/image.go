package repository

import (
	"sampling/config"
	"sampling/models"

	"gorm.io/gorm"
)

type ImageRepository struct {
	db *gorm.DB
}

func NewImageRepository() *ImageRepository {
	return &ImageRepository{db: config.DB}
}

// CreateImage creates a new image record
func (r *ImageRepository) CreateImage(image *models.Image) error {
	return r.db.Create(image).Error
}

// GetImagesBySampleID retrieves images by sample ID
func (r *ImageRepository) GetImagesBySampleID(sampleID uint) ([]models.Image, error) {
	var images []models.Image
	err := r.db.Where("sample_id = ?", sampleID).Find(&images).Error
	return images, err
}

// GetImagesByUserID retrieves images by user ID
func (r *ImageRepository) GetImagesByUserID(userID uint) ([]models.Image, error) {
	var images []models.Image
	err := r.db.Where("user_id = ?", userID).Find(&images).Error
	return images, err
}

// GetImageByID retrieves image by ID
func (r *ImageRepository) GetImageByID(imageID uint) (*models.Image, error) {
	var image models.Image
	err := r.db.First(&image, imageID).Error
	return &image, err
}
