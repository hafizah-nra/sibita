class Validator {
  static String? required(String? v) =>
      v == null || v.isEmpty ? 'Wajib diisi' : null;
  static String? email(String? v) =>
      v == null || !v.contains('@') ? 'Email tidak valid' : null;
}
