# Nirbhor — Auth API Reference (Flutter)

---

## Base URL

| Environment | URL |
|-------------|-----|
| Android emulator | `http://10.0.2.2:3000` |
| iOS simulator | `http://127.0.0.1:3000` |
| Physical device (local) | `http://<your-machine-ip>:3000` |
| Production | `https://api.nirbhor.com` |

---

## Headers

**Unauthenticated requests:**
```
Content-Type: application/json
```

**Authenticated requests:**
```
Content-Type: application/json
Authorization: Bearer <access_token>
```

---

## Response Envelope

Every response — success or error — uses this exact shape:

```json
{
  "status": "success",
  "message": "Human readable message",
  "data": { } | null
}
```

**On error:**
```json
{
  "status": "error",
  "message": "What went wrong",
  "data": null
}
```

`data` is `null` for errors and for endpoints that return nothing meaningful on success (logout, change-password).

---

## Tokens

| Token | Key in response | Lifetime | Where to store |
|-------|----------------|----------|---------------|
| Access token | `data.tokens.access_token` | 15 minutes | Memory only |
| Refresh token | `data.tokens.refresh_token` | 7 days | Secure storage |

When the access token expires, call `POST /auth/refresh` with the refresh token to get a new pair. Attach the new access token to all subsequent requests.

---

## Auth Flow Overview

```
Enter email  →  POST /auth/email
    ├── data.status = "password_required"
    │       └──  POST /auth/login
    │
    └── data.status = "otp_sent"
            └──  POST /auth/verify-otp  (returns setup_token)
                    ├── data.hint = "new_user"
                    │       └──  POST /auth/complete-setup
                    │
                    └── data.hint = "google_no_password"
                            └──  POST /auth/reset-password  (scope: set_password)

Google button  →  POST /auth/google

Forgot password  →  POST /auth/forgot-password
                         └──  POST /auth/verify-otp
                                  └──  POST /auth/reset-password  (scope: password_reset)
```

---

## Endpoints

---

### POST `/auth/email`

Check if email exists and determine next step. Sends OTP automatically when needed.

**Request body:**
```json
{
  "email": "user@example.com"
}
```

**Response — new user (OTP sent):**
```json
{
  "status": "success",
  "message": "Email check complete",
  "data": {
    "status": "otp_sent",
    "hint": "new_user",
    "otp_verification_token": "eyJ..."
  }
}
```

**Response — existing user with password:**
```json
{
  "status": "success",
  "message": "Email check complete",
  "data": {
    "status": "password_required",
    "hint": "existing_password"
  }
}
```

**Response — Google-only account (no password set):**
```json
{
  "status": "success",
  "message": "Email check complete",
  "data": {
    "status": "otp_sent",
    "hint": "google_no_password",
    "otp_verification_token": "eyJ..."
  }
}
```

| `data.status` | `data.hint` | Next screen |
|------------|---------|-------------|
| `otp_sent` | `new_user` | OTP screen → Complete setup |
| `password_required` | `existing_password` | Password screen → Login |
| `otp_sent` | `google_no_password` | OTP screen → Set password |

**Errors:**

| HTTP | `message` |
|------|-----------|
| 400 | `Valid email required` |

---

### POST `/auth/verify-otp`

Verify the OTP entered by the user. Returns a `setup_token` valid for 10 minutes.

**Request body:**
```json
{
  "otp_verification_token": "eyJ...",
  "otp": "483920"
}
```

**Response:**
```json
{
  "status": "success",
  "message": "OTP verified",
  "data": {
    "status": "otp_verified",
    "setup_token": "eyJ..."
  }
}
```

**Errors:**

| HTTP | `message` |
|------|-----------|
| 400 | `Invalid or expired OTP token` |
| 400 | `Invalid OTP` |

---

### POST `/auth/complete-setup`

Register a new user. Use the `setup_token` from `/auth/verify-otp` (scope must be `registration`).

**Request body:**
```json
{
  "setup_token": "eyJ...",
  "name": "John Doe",
  "password": "SecurePass123",
  "device_token": "fcm_token_here",
  "device_type": "android"
}
```

`device_token` and `device_type` are optional but required for push notifications.  
`device_type` values: `"android"` or `"ios"`

**Response (HTTP 201):**
```json
{
  "status": "success",
  "message": "Account created",
  "data": {
    "tokens": {
      "access_token": "eyJ...",
      "refresh_token": "eyJ..."
    },
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "email": "user@example.com",
      "name": "John Doe",
      "avatar_url": null,
      "created_at": "2026-05-16T10:00:00.000Z"
    }
  }
}
```

**Errors:**

| HTTP | `message` |
|------|-----------|
| 400 | `Invalid or expired setup token` |
| 400 | `Invalid setup token scope` |
| 400 | `Name is required` |
| 400 | `Password must be at least 6 characters` |
| 409 | `User already exists` |

---

### POST `/auth/login`

Login with email and password.

**Request body:**
```json
{
  "email": "user@example.com",
  "password": "SecurePass123",
  "device_token": "fcm_token_here",
  "device_type": "android"
}
```

**Response (HTTP 200):**
```json
{
  "status": "success",
  "message": "Login successful",
  "data": {
    "tokens": {
      "access_token": "eyJ...",
      "refresh_token": "eyJ..."
    },
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "email": "user@example.com",
      "name": "John Doe",
      "avatar_url": null,
      "created_at": "2026-05-16T10:00:00.000Z"
    }
  }
}
```

**Errors:**

| HTTP | `message` |
|------|-----------|
| 401 | `Invalid email or password` |

---

### POST `/auth/google`

Authenticate with a Google ID token obtained from Google Sign-In SDK.  
Auto-registers new users. Links Google account to existing email if found.

**Request body:**
```json
{
  "id_token": "google_id_token_from_sdk",
  "device_token": "fcm_token_here",
  "device_type": "ios"
}
```

**Response:**
- HTTP `201` for new users
- HTTP `200` for existing users

```json
{
  "status": "success",
  "message": "Google authentication successful",
  "data": {
    "tokens": {
      "access_token": "eyJ...",
      "refresh_token": "eyJ..."
    },
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "email": "user@example.com",
      "name": "John Doe",
      "avatar_url": "https://lh3.googleusercontent.com/...",
      "created_at": "2026-05-16T10:00:00.000Z"
    }
  }
}
```

**Errors:**

| HTTP | `message` |
|------|-----------|
| 401 | `Invalid Google token` |

**Google Client ID:** `940233733536-vt8k70te98j0ufqhg10llp30p95s43nv.apps.googleusercontent.com`

---

### POST `/auth/forgot-password`

Send a password reset OTP to the email. Always returns success even if email not found (prevents enumeration).

**Request body:**
```json
{
  "email": "user@example.com"
}
```

**Response:**
```json
{
  "status": "success",
  "message": "OTP sent",
  "data": {
    "status": "otp_sent",
    "otp_verification_token": "eyJ..."
  }
}
```

Pass `otp_verification_token` to the OTP screen, then call `POST /auth/verify-otp`.  
After that, call `POST /auth/reset-password` with the resulting `setup_token`.

---

### POST `/auth/reset-password`

Set a new password using the `setup_token` from OTP verification.

**Request body:**
```json
{
  "setup_token": "eyJ...",
  "new_password": "NewSecurePass123"
}
```

**Response — password reset flow (`scope: password_reset`):**
```json
{
  "status": "success",
  "message": "Password updated successfully",
  "data": {
    "message": "Password updated successfully"
  }
}
```

**Response — set password flow (`scope: set_password`, Google-only account):**
```json
{
  "status": "success",
  "message": "Password updated successfully",
  "data": {
    "message": "Password updated successfully",
    "tokens": {
      "access_token": "eyJ...",
      "refresh_token": "eyJ..."
    }
  }
}
```

When `data.tokens` is present, the user is automatically logged in — store the tokens and navigate to home.

**Errors:**

| HTTP | `message` |
|------|-----------|
| 400 | `Invalid or expired setup token` |
| 400 | `Invalid token scope` |
| 400 | `User not found` |

---

### POST `/auth/refresh`

Exchange a refresh token for a new access + refresh token pair.  
Call this when any request returns HTTP 401.

**Request body:**
```json
{
  "refresh_token": "eyJ..."
}
```

**Response:**
```json
{
  "status": "success",
  "message": "Tokens refreshed",
  "data": {
    "access_token": "eyJ...",
    "refresh_token": "eyJ..."
  }
}
```

Store the new `refresh_token` and use the new `access_token` for all subsequent requests.

**Errors:**

| HTTP | `message` |
|------|-----------|
| 401 | `Invalid refresh token` |
| 401 | `User not found` |

---

### GET `/auth/profile`

Get the current user's profile. **Requires auth.**

**Response:**
```json
{
  "status": "success",
  "message": "Profile fetched",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "name": "John Doe",
    "avatar_url": "https://...",
    "created_at": "2026-05-16T10:00:00.000Z"
  }
}
```

---

### PUT `/auth/profile`

Update name and/or avatar URL. **Requires auth.**

**Request body:**
```json
{
  "name": "John Updated",
  "avatar_url": "https://example.com/avatar.jpg"
}
```

`avatar_url` is optional.

**Response:**
```json
{
  "status": "success",
  "message": "Profile updated",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "name": "John Updated",
    "avatar_url": "https://example.com/avatar.jpg",
    "created_at": "2026-05-16T10:00:00.000Z"
  }
}
```

**Errors:**

| HTTP | `message` |
|------|-----------|
| 400 | `Name is required` |

---

### PUT `/auth/change-password`

Change password while logged in. **Requires auth.**

**Request body:**
```json
{
  "old_password": "CurrentPass123",
  "new_password": "NewPass456"
}
```

**Response:**
```json
{
  "status": "success",
  "message": "Password changed",
  "data": null
}
```

**Errors:**

| HTTP | `message` |
|------|-----------|
| 400 | `Account has no password set` |
| 400 | `Old password is incorrect` |

---

### POST `/auth/logout`

Remove the FCM device token so push notifications stop. **Requires auth.**

**Request body:**
```json
{
  "device_token": "fcm_token_here"
}
```

**Response:**
```json
{
  "status": "success",
  "message": "Logged out successfully",
  "data": null
}
```

After this call, discard the stored access and refresh tokens on the client side.

---

## User Object (reference)

All endpoints that return a user use this exact shape:

```json
{
  "id": "uuid-string",
  "email": "user@example.com",
  "name": "John Doe",
  "avatar_url": "https://..." | null,
  "created_at": "2026-05-16T10:00:00.000Z"
}
```

---

## Common Error Codes

| HTTP | When it happens |
|------|----------------|
| 400 | Validation failed, invalid token, bad scope |
| 401 | Wrong password, expired/invalid token |
| 403 | Correct token but not allowed |
| 404 | User not found |
| 409 | Email already registered |
| 423 | Pending settlement blocks action |
| 500 | Server error |
