# TODO List - Backend Sampling API Implementation

## Auth/Login Feature
- [x] Create middleware/auth.go for JWT authentication
- [x] Create repository/user.go for user queries (updated with bcrypt and register methods)
- [x] Create controllers/auth.go for login handler (added register handler)
- [x] Add auth routes to routes/routes.go (login and register)

## Station/QR Scan Feature
- [x] Create repository/station.go for station queries
- [x] Create controllers/station.go for list stations and scan QR handlers
- [x] Add station routes to routes/routes.go

## Sample Upload Feature
- [x] Create repository/sample.go for sample queries
- [x] Create repository/image.go for image queries
- [x] Create controllers/sample.go for create sample with images handler
- [x] Add sample routes to routes/routes.go

## Sync Offline/Online Feature
- [x] Create controllers/sync.go for sync data handler
- [x] Add sync routes to routes/routes.go

## General Setup
- [x] Create routes/routes.go for all route setup
- [x] Update main.go to use routes
- [x] Create docs/api.md for API documentation

## Database Migration Fixes
- [x] Fix table name issues by adding TableName() methods to all models
- [x] Reorder AutoMigrate to resolve foreign key dependencies
- [x] Add email and phone fields to User model for register API

## Testing
- [ ] Test register endpoint
- [ ] Test login endpoint
- [ ] Test stations list endpoint
- [ ] Test scan QR endpoint
- [ ] Test sample upload endpoint
- [ ] Test sync endpoint
