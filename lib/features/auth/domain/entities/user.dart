class User {
  final String id;
  final String email;
  final String? name;
  final String token;

  const User({
    required this.id,
    required this.email,
    this.name,
    required this.token,
  });
}