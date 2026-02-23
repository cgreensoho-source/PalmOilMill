package controllers

import (
	"regexp"
	"sampling/config"
	"sampling/models"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/golang-jwt/jwt/v4"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

type AuthController struct{}

func NewAuthController() *AuthController {
	return &AuthController{}
}

// ================= LOGIN =================

type LoginRequest struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

type LoginResponse struct {
	Token string      `json:"token"`
	User  models.User `json:"user"`
}

// Login godoc
// @Summary      Login User
// @Description  Autentikasi user untuk mendapatkan token JWT
// @Tags         auth
// @Accept       json
// @Produce      json
// @Param        login  body      LoginRequest  true  "User Credentials"
// @Success      200    {object}  LoginResponse
// @Failure      401    {object}  map[string]string "Invalid username or password"
// @Router       /login [post]
func (ctrl *AuthController) Login(c *fiber.Ctx) error {
	var req LoginRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid request"})
	}

	var user models.User
	// Load roles untuk cek apakah dia admin atau bukan
	err := config.DB.
		Preload("Roles").
		Where("username = ?", req.Username).
		First(&user).Error

	if err != nil {
		return c.Status(401).JSON(fiber.Map{"error": "Invalid username or password"})
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.Password)); err != nil {
		return c.Status(401).JSON(fiber.Map{"error": "Invalid username or password"})
	}

	// --- LOGIKA PENENTUAN ROLE UNTUK JWT ---
	// Kita ambil satu role utama (misal admin punya prioritas)
	userRole := "user" // default
	for _, r := range user.Roles {
		if r.RoleName == "admin" {
			userRole = "admin"
			break
		} else if r.RoleName == "asisten" {
			userRole = "asisten"
		}
	}

	// JWT - MASUKKAN ROLE KE CLAIMS
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user_id": user.UserID,
		"role":    userRole, // INI YANG TADI ILANG!
		"exp":     time.Now().Add(24 * time.Hour).Unix(),
	})

	tokenString, err := token.SignedString([]byte("your-secret-key"))
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed generate token"})
	}

	user.Password = ""

	return c.JSON(LoginResponse{
		Token: tokenString,
		User:  user,
	})
}

// ================= REGISTER =================

type RegisterRequest struct {
	Nip             string   `json:"nip"`
	Username        string   `json:"username"`
	Email           string   `json:"email"`
	Phone           string   `json:"phone"`
	Password        string   `json:"password"`
	ConfirmPassword string   `json:"confirm_password"`
	Gender          string   `json:"gender"`
	Roles           []string `json:"roles"`
}

type RegisterResponse struct {
	Message string      `json:"message"`
	User    models.User `json:"user"`
}

// Register godoc
// @Summary      Register User Baru
// @Description  Membuat akun user baru beserta penentuan Role
// @Tags         auth
// @Accept       json
// @Produce      json
// @Param        register  body      RegisterRequest  true  "User Data"
// @Success      201       {object}  RegisterResponse
// @Failure      400       {object}  map[string]string "Validation error"
// @Router       /register [post]
func (ctrl *AuthController) Register(c *fiber.Ctx) error {
	var req RegisterRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid request"})
	}

	if req.Nip == "" || req.Username == "" || req.Password == "" {
		return c.Status(400).JSON(fiber.Map{"error": "Required fields missing"})
	}

	if req.Password != req.ConfirmPassword {
		return c.Status(400).JSON(fiber.Map{"error": "Password mismatch"})
	}

	if len(req.Password) < 6 {
		return c.Status(400).JSON(fiber.Map{"error": "Password minimal 6 karakter"})
	}

	if req.Email != "" {
		emailRegex := regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`)
		if !emailRegex.MatchString(req.Email) {
			return c.Status(400).JSON(fiber.Map{"error": "Invalid email"})
		}
	}

	hashed, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Hash gagal"})
	}

	user := models.User{
		Nip:      req.Nip,
		Username: req.Username,
		Email:    req.Email,
		Phone:    req.Phone,
		Password: string(hashed),
		Gender:   req.Gender,
	}

	err = config.DB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(&user).Error; err != nil {
			return err
		}

		var roles []models.Role
		if len(req.Roles) > 0 {
			// Mencari ID role berdasarkan nama role yang dikirim (misal: "admin")
			if err := tx.Where("role_name IN ?", req.Roles).Find(&roles).Error; err != nil {
				return err
			}
		}

		if len(roles) > 0 {
			if err := tx.Model(&user).Association("Roles").Append(&roles); err != nil {
				return err
			}
		}

		return nil
	})

	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"error": "Gagal register: " + err.Error(),
		})
	}

	config.DB.Preload("Roles").First(&user, user.UserID)
	user.Password = ""

	return c.Status(201).JSON(RegisterResponse{
		Message: "User registered successfully",
		User:    user,
	})
}
