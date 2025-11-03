class FirefighterUser {
  String id;
  String givenName;
  String firstSurname;
  String? secondSurname;
  int role;
  String? watchedByUserId;
  Set<String> watchesUsersId = {};

  FirefighterUser({
    required this.id,
    required this.givenName,
    required this.firstSurname,
    required this.secondSurname,
    required this.role,
    this.watchedByUserId,
    this.watchesUsersId = const {}
  });

  String get fullName => "$givenName $firstSurname${secondSurname != null ? " $secondSurname" : ""}";

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'givenName': givenName,
      'firstSurname': firstSurname,
      'secondSurname': secondSurname,
      'role': role,
      'watchedByUserId': watchedByUserId,
      'watchesUsersId': watchesUsersId.toList(),
    };
  }

  factory FirefighterUser.fromJson(Map<String, dynamic> json) {
    return FirefighterUser(
      id: json['id'],
      givenName: json['givenName'],
      firstSurname: json['firstSurname'],
      secondSurname: json['secondSurname'],
      role: json['role'],
      watchedByUserId: json['watchedByUserId'],
      watchesUsersId: (json['watchesUsersId'] as List<dynamic>?)?.map((e) => e as String).toSet() ?? {},
    );
  }
}