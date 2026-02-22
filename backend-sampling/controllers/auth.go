package controllers

import (
	"regexp"
	"sampling/models"
	"sampling/repository"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/golang-jwt/jwt/v4"
	"golang.org/x/crypto/bcrypt"
)

type AuthController struct {
	userRepo *repository.UserRepository
}

func NewAuthController() *AuthController {
	return &AuthController{
		userRepo: repository.NewUserRepository(),
	}
}

// LoginRequest represents login request body
type LoginRequest struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

// LoginResponse represents login response
type LoginResponse struct {
	Token string      `json:"token"`
	User  models.User `json:"user"`
}

// Login handles user authentication (whitelist check)
func (ctrl *AuthController) Login(c *fiber.Ctx) error {
	var req LoginRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid request body"})
	}

	user, err := ctrl.userRepo.GetUserByUsernamePassword(req.Username, req.Password)
	if err != nil {
		return c.Status(401).JSON(fiber.Map{"error": "Invalid username or password"})
	}

	// Generate JWT token
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user_id": user.UserID,
		"exp":     time.Now().Add(time.Hour * 24).Unix(), // 24 hours
	})

	tokenString, err := token.SignedString([]byte("your-secret-key")) // Ganti dengan secret key yang aman
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to generate token"})
	}

	response := LoginResponse{
		Token: tokenString,
		User:  *user,
	}

	return c.JSON(response)
}

// RegisterRequest represents register request body
type RegisterRequest struct {
	Nip             string `json:"nip"`
	Username        string `json:"username"`
	Email           string `json:"email"`
	Phone           string `json:"phone"`
	Password        string `json:"password"`
	ConfirmPassword string `json:"confirm_password"`
	Gender          string `json:"gender"`
}

// RegisterResponse represents register response
type RegisterResponse struct {
	Message string      `json:"message"`
	User    models.User `json:"user"`
}

// Register handles user registration
func (ctrl *AuthController) Register(c *fiber.Ctx) error {
	var req RegisterRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid request body"})
	}

	// Validate required fields
	if req.Nip == "" || req.Username == "" || req.Password == "" || req.ConfirmPassword == "" {
		return c.Status(400).JSON(fiber.Map{"error": "NIP, username, password, and confirm password are required"})
	}

	// Validate password confirmation
	if req.Password != req.ConfirmPassword {
		return c.Status(400).JSON(fiber.Map{"error": "Password and confirm password do not match"})
	}

	// Validate password strength (minimum 6 characters)
	if len(req.Password) < 6 {
		return c.Status(400).JSON(fiber.Map{"error": "Password must be at least 6 characters long"})
	}

	// Validate email format if provided
	if req.Email != "" {
		emailRegex := regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`)
		if !emailRegex.MatchString(req.Email) {
			return c.Status(400).JSON(fiber.Map{"error": "Invalid email format"})
		}
	}

	// Validate phone format if provided
	if req.Phone != "" {
		phoneRegex := regexp.MustCompile(`^[0-9+\-\s()]{10,15}$`)
		if !phoneRegex.MatchString(req.Phone) {
			return c.Status(400).JSON(fiber.Map{"error": "Invalid phone number format"})
		}
	}

	// Check if user already exists
	exists, err := ctrl.userRepo.CheckUserExists(req.Nip, req.Username, req.Email, req.Phone)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to check user existence"})
	}
	if exists {
		return c.Status(409).JSON(fiber.Map{"error": "User with this NIP, username, email, or phone already exists"})
	}

	// Hash password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to hash password"})
	}

	// Create user
	user := models.User{
		Nip:      req.Nip,
		Username: req.Username,
		Email:    req.Email,
		Phone:    req.Phone,
		Password: string(hashedPassword),
		Gender:   req.Gender,
	}

	if err := ctrl.userRepo.CreateUser(&user); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to create user"})
	}

	// Remove password from response
	user.Password = ""

	response := RegisterResponse{
		Message: "User registered successfully",
		User:    user,
	}

	return c.Status(201).JSON(response)
}
