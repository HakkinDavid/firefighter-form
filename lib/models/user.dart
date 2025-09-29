class User {
  String id;
  String name;
  String lastName;
  String email;
  String createdAt;
  int role;

  User({
    required this.id,
    required this.name,
    required this.lastName,
    required this.email,
    required this.createdAt,
    required this.role
  });
}