package middleware

import (
	"strings"

	"github.com/gofiber/fiber/v2"
	"github.com/golang-jwt/jwt/v4"
)

// JWTMiddleware validates JWT token (Standard Check)
func JWTMiddleware(c *fiber.Ctx) error {
	authHeader := c.Get("Authorization")
	if authHeader == "" {
		return c.Status(401).JSON(fiber.Map{"error": "Missing authorization header"})
	}

	tokenString := strings.TrimPrefix(authHeader, "Bearer ")

	// Pastikan secret key sama dengan yang ada di AuthController saat Login
	token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		return []byte("your-secret-key"), nil
	})

	if err != nil || !token.Valid {
		return c.Status(401).JSON(fiber.Map{"error": "Token tidak valid atau expired"})
	}

	// Simpan SEMUA claims ke Locals supaya bisa dibaca middleware berikutnya
	claims, ok := token.Claims.(jwt.MapClaims)
	if ok {
		c.Locals("user_id", claims["user_id"])
		c.Locals("role", claims["role"]) // Pastikan saat login, role disimpan di JWT
	}

	return c.Next()
}

// AdminOnly membatasi akses hanya untuk user dengan role 'admin'
func AdminOnly(c *fiber.Ctx) error {
	// Ambil role dari Locals yang sudah diset oleh JWTMiddleware
	role := c.Locals("role")

	if role != "admin" {
		return c.Status(403).JSON(fiber.Map{
			"error": "Access Forbidden: Hanya Admin yang diizinkan",
		})
	}

	return c.Next()
}
