class Endpoints {
  static const base = 'https://crud.teamrabbil.com/api/v1';

  /// Authentication
  static const String register = '/auth/register/';
  static const String login = '/auth/login';
  static const String forgotPassword = '/auth/forgot_password/';
  static const String resetPassword = '/auth/reset_password/';
  static const String refreshToken = '/auth/refresh_token/';

  /// OTP
  static const String verifyOtp = '/otp/verify_otp/';
  static const String resendOtp = '/otp/resend_otp/';

  /// Product Endpoints
  static const String getProduct = '/ReadProduct';
  static const String createProduct = '/CreateProduct';

  //  Constant paths with placeholders for Retrofit
  static const String updateProductPath = '/UpdateProduct/{id}';
  static const String deleteProductPath = '/DeleteProduct/{id}';

  /// Optional full URL builders (runtime use, not for annotations)
  static String get getProductUrl => '$base$getProduct';
  static String get createProductUrl => '$base$createProduct';
  static String updateProductUrl(String id) => '$base/UpdateProduct/$id';
  static String deleteProductUrl(String id) => '$base/DeleteProduct/$id';
}
