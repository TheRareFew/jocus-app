class User {
  final String id;
  final String email;
  final String role; // 'creator' or 'viewer'
  
  User({
    required this.id,
    required this.email,
    required this.role,
  });
} 