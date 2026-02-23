package repository

import (
	"sampling/config"
	"sampling/models"

	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

type UserRepository struct {
	db *gorm.DB
}

func NewUserRepository() *UserRepository {
	return &UserRepository{db: config.DB}
}

// 1. GetUserByUsernamePassword (Untuk Login)
func (r *UserRepository) GetUserByUsernamePassword(username, password string) (*models.User, error) {
	var user models.User
	// Kita preload Roles sekalian supaya pas login langsung tahu dia Admin atau bukan
	err := r.db.Preload("Roles").Where("username = ?", username).First(&user).Error
	if err != nil {
		return nil, err
	}

	err = bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(password))
	if err != nil {
		return nil, err
	}

	return &user, nil
}

// 2. GetUserByID (Hanya Satu Versi - Mendukung Detail & Edit)
func (r *UserRepository) GetUserByID(userID uint) (*models.User, error) {
	var user models.User
	// Tambahkan Preload Roles agar Admin bisa lihat role user tersebut
	err := r.db.Preload("Roles").First(&user, userID).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

// 3. CreateUser (Dengan Transaction & Role Mapping)
func (r *UserRepository) CreateUser(user *models.User, roleNames []string) error {
	return r.db.Transaction(func(tx *gorm.DB) error {
		// Simpan data User (Abaikan asosiasi dulu agar tidak error FK)
		if err := tx.Omit(clause.Associations).Create(user).Error; err != nil {
			return err
		}

		for _, name := range roleNames {
			var role models.Role
			if err := tx.Where("role_name = ?", name).First(&role).Error; err != nil {
				return err
			}

			userRole := models.UserRole{
				UserID: user.UserID,
				RoleID: role.RoleID,
			}

			if err := tx.Create(&userRole).Error; err != nil {
				return err
			}
		}
		// Load ulang data lengkap dengan roles
		return tx.Preload("Roles").First(user, user.UserID).Error
	})
}

// 4. CheckUserExists (Versi Ringkas - Untuk Validasi Registrasi)
func (r *UserRepository) CheckUserExists(nip, username, email, phone string) (bool, error) {
	var count int64
	err := r.db.Model(&models.User{}).
		Where("nip = ? OR username = ? OR email = ? OR phone = ?", nip, username, email, phone).
		Count(&count).Error

	if err != nil {
		return false, err
	}
	return count > 0, nil
}

// 5. UpdateUser (Untuk CRUD Admin & Reset Password)
func (r *UserRepository) UpdateUser(user *models.User) error {
	// Pake Save buat update seluruh field termasuk password yang sudah di-hash
	return r.db.Save(user).Error
}

// 6. DeleteUser (Untuk Hapus Akun)
func (r *UserRepository) DeleteUser(id uint) error {
	// CASCADE akan dihandle database jika skema benar,
	// tapi GORM juga bisa handle jika relasi didefinisikan
	return r.db.Delete(&models.User{}, id).Error
}
