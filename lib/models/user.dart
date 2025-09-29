class User {
  String id;
  String name;
  String lastName;
  int role;
  String? watchedByUserId;
  Set<String> watchesUsersId = {};

  User({
    required this.id,
    required this.name,
    required this.lastName,
    required this.role,
    this.watchedByUserId,
    this.watchesUsersId = const {}
  });
}