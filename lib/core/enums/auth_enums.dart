enum AuthCheckStatus {
  otpSent,
  passwordRequired,
}

enum AuthHint {
  newUser,
  existingPassword,
  googleNoPassword,
}

enum AuthLoadingSource {
  session,
  emailCheck,
  google,
  otp,
  login,
  completeSetup,
  forgotPassword,
  resetPassword,
  logout,
}
