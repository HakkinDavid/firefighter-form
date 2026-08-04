class LocalUserAccount {
  final String userId;
  final String email;
  final String givenName;
  final String firstSurname;
  final String? secondSurname;
  final int role;
  final String? refreshToken;
  final DateTime lastLoginAt;
  final bool isSessionValid;

  LocalUserAccount({
    required this.userId,
    required this.email,
    required this.givenName,
    required this.firstSurname,
    this.secondSurname,
    required this.role,
    this.refreshToken,
    required this.lastLoginAt,
    this.isSessionValid = true,
  });

  String get fullName {
    final parts = [givenName, firstSurname, if (secondSurname != null && secondSurname!.isNotEmpty) secondSurname!];
    return parts.join(' ');
  }

  String get roleName {
    switch (role) {
      case 2:
        return 'Administrador';
      case 1:
        return 'Supervisor';
      case 0:
      default:
        return 'Bombero';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'email': email,
      'given_name': givenName,
      'first_surname': firstSurname,
      'second_surname': secondSurname,
      'role': role,
      'refresh_token': refreshToken,
      'last_login_at': lastLoginAt.toIso8601String(),
      'is_session_valid': isSessionValid ? 1 : 0,
    };
  }

  factory LocalUserAccount.fromMap(Map<String, dynamic> map) {
    return LocalUserAccount(
      userId: map['user_id'] as String,
      email: map['email'] as String? ?? '',
      givenName: map['given_name'] as String? ?? '',
      firstSurname: map['first_surname'] as String? ?? '',
      secondSurname: map['second_surname'] as String?,
      role: map['role'] as int? ?? 0,
      refreshToken: map['refresh_token'] as String?,
      lastLoginAt: map['last_login_at'] != null
          ? DateTime.parse(map['last_login_at'] as String)
          : DateTime.now(),
      isSessionValid: (map['is_session_valid'] as int? ?? 1) == 1,
    );
  }

  LocalUserAccount copyWith({
    String? refreshToken,
    DateTime? lastLoginAt,
    bool? isSessionValid,
    int? role,
  }) {
    return LocalUserAccount(
      userId: userId,
      email: email,
      givenName: givenName,
      firstSurname: firstSurname,
      secondSurname: secondSurname,
      role: role ?? this.role,
      refreshToken: refreshToken ?? this.refreshToken,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isSessionValid: isSessionValid ?? this.isSessionValid,
    );
  }
}
