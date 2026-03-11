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
    this.watchesUsersId = const {},
  });

  String get fullName =>
      "$givenName $firstSurname${secondSurname != null ? " $secondSurname" : ""}";
  String get roleName => switch (role) {
    2 => "Administrador",
    1 => "Supervisor",
    0 => "Bombero",
    _ => "Usuario",
  };

  bool get isFirefighter => role >= 0;
  bool get isSupervisor => role >= 1;
  bool get isAdministrator => role >= 2;

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
      watchesUsersId:
          (json['watchesUsersId'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          {},
    );
  }
}
