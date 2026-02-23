package controllers

import (
	"sampling/config"
	"sampling/models"
	"sampling/repository"

	"github.com/gofiber/fiber/v2"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

type AdminUserController struct {
	userRepo *repository.UserRepository
}

func NewAdminUserController() *AdminUserController {
	return &AdminUserController{
		userRepo: repository.NewUserRepository(),
	}
}

// 2. Struct untuk nangkep request (pake pointer biar bisa cek nil)
type UpdateRequest struct {
	Nip      *string  `json:"nip"`
	Username *string  `json:"username"`
	Email    *string  `json:"email"`
	Phone    *string  `json:"phone"`
	Password *string  `json:"password"`
	Gender   *string  `json:"gender"`
	Roles    []string `json:"roles"`
}

// UpdateUserByAdmin godoc
// @Summary      Update User oleh Admin
// @Description  Memperbarui data user tertentu berdasarkan ID. Hanya field yang dikirim yang akan diupdate.
// @Tags         admin-users
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id    path      int            true  "Target User ID"
// @Param        user  body      UpdateRequest  true  "Update Data User"
// @Success      200   {object}  map[string]string "message: Data user berhasil diperbarui"
// @Failure      404   {object}  map[string]string "error: User tidak ditemukan"
// @Router       /admin/users/{id} [put]
func (ctrl *AdminUserController) UpdateUserByAdmin(c *fiber.Ctx) error {
	targetID, _ := c.ParamsInt("id")

	// 1. Ambil data user LENGKAP dari database dulu
	var user models.User
	err := config.DB.Preload("Roles").First(&user, targetID).Error
	if err != nil {
		return c.Status(404).JSON(fiber.Map{"error": "User tidak ditemukan"})
	}

	var req UpdateRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Format data salah"})
	}

	// 3. LOGIKA UPDATE: Hanya ganti kalau field-nya DIISI di Postman
	if req.Nip != nil {
		user.Nip = *req.Nip
	}
	if req.Username != nil {
		user.Username = *req.Username
	}
	if req.Email != nil {
		user.Email = *req.Email
	}
	if req.Phone != nil {
		user.Phone = *req.Phone
	}
	if req.Gender != nil {
		user.Gender = *req.Gender
	}

	// Jika password diisi, hash dan update
	if req.Password != nil && *req.Password != "" {
		hashedPassword, _ := bcrypt.GenerateFromPassword([]byte(*req.Password), bcrypt.DefaultCost)
		user.Password = string(hashedPassword)
	}

	// 4. Update ke Database pakai Updates (hanya kolom yang berubah)
	if err := config.DB.Save(&user).Error; err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Gagal update data user"})
	}

	// 5. Update Roles jika ada (Many to Many)
	if req.Roles != nil {
		var newRoles []models.Role
		config.DB.Where("role_name IN ?", req.Roles).Find(&newRoles)
		// Clear roles lama dan ganti yang baru
		config.DB.Model(&user).Association("Roles").Replace(newRoles)
	}

	return c.JSON(fiber.Map{
		"message": "Data user berhasil diperbarui tanpa menghapus data lama",
	})
}

// DeleteUser godoc
// @Summary      Hapus User Permanen (Clean Delete)
// @Description  Menghapus user beserta semua relasi datanya di tabel images, samples, dan roles secara permanen (Clean up).
// @Tags         admin-users
// @Produce      json
// @Security     BearerAuth
// @Param        id   path      int  true  "Target User ID"
// @Success      200  {object}  map[string]string "message: User dan seluruh datanya berhasil dibersihkan"
// @Failure      500  {object}  map[string]string "error: Gagal total bantai user"
// @Router       /admin/users/{id} [delete]
func (ctrl *AdminUserController) DeleteUser(c *fiber.Ctx) error {
	id, _ := c.ParamsInt("id")

	// Mulai Transaksi agar database tetap konsisten
	err := config.DB.Transaction(func(tx *gorm.DB) error {

		// 1. Ambil data user beserta relasi Roles-nya
		var user models.User
		if err := tx.Preload("Roles").First(&user, id).Error; err != nil {
			return err // User tidak ditemukan
		}

		// 2. HAPUS RELASI DI TABEL PIVOT (user_roles)
		// Ini akan menghapus data di tabel 'user_roles' tanpa menghapus data di tabel 'roles'
		if err := tx.Model(&user).Association("Roles").Clear(); err != nil {
			return err
		}

		// 3. HAPUS IMAGES
		// Foto petugas/sampel harus dihapus duluan karena biasanya FK ke user & sample
		if err := tx.Exec("DELETE FROM images WHERE user_id = ?", id).Error; err != nil {
			return err
		}

		// 4. HAPUS SAMPLES
		// Data sampling petugas dihapus
		if err := tx.Exec("DELETE FROM samples WHERE user_id = ?", id).Error; err != nil {
			return err
		}

		// 5. HAPUS USER (Gembong Utama)
		// Unscoped() digunakan jika model lo pake gorm.Model (Soft Delete) agar terhapus permanen
		if err := tx.Unscoped().Delete(&user).Error; err != nil {
			return err
		}

		return nil
	})

	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"error": "Gagal total bantai user: " + err.Error(),
		})
	}

	return c.JSON(fiber.Map{
		"message": "User ID " + c.Params("id") + " dan seluruh datanya di tabel images, samples, dan roles berhasil dibersihkan!",
	})
}
