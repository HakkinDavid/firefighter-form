class FirefighterUser {
  String id;
  String givenName;
  String firstSurname;
  String secondSurname;
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

  String get fullName => "$givenName $firstSurname $secondSurname";
}