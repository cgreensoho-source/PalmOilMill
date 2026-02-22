package repository

import (
	"sampling/config"
	"sampling/models"

	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

type UserRepository struct {
	db *gorm.DB
}

func NewUserRepository() *UserRepository {
	return &UserRepository{db: config.DB}
}

// GetUserByUsernamePassword retrieves user by username and password (whitelist check)
func (r *UserRepository) GetUserByUsernamePassword(username, password string) (*models.User, error) {
	var user models.User
	err := r.db.Where("username = ?", username).First(&user).Error
	if err != nil {
		return nil, err
	}

	err = bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(password))
	if err != nil {
		return nil, err
	}

	return &user, nil
}

// GetUserByID retrieves user by ID
func (r *UserRepository) GetUserByID(userID uint) (*models.User, error) {
	var user models.User
	err := r.db.First(&user, userID).Error
	return &user, err
}

// CreateUser creates a new user
func (r *UserRepository) CreateUser(user *models.User) error {
	return r.db.Create(user).Error
}

// CheckUserExists checks if user exists by nip, username, email, or phone
func (r *UserRepository) CheckUserExists(nip, username, email, phone string) (bool, error) {
	var count int64
	query := r.db.Model(&models.User{})

	if nip != "" {
		query = query.Where("nip = ?", nip)
	}
	if username != "" {
		query = query.Where("username = ?", username)
	}
	if email != "" {
		query = query.Where("email = ?", email)
	}
	if phone != "" {
		query = query.Where("phone = ?", phone)
	}

	err := query.Count(&count).Error
	return count > 0, err
}
