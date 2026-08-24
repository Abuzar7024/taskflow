import 'package:equatable/equatable.dart';

import 'enums.dart';

/// Token pair plus absolute expiry timestamps.
///
/// The mock backend returns relative lifetimes; they are converted to absolute
/// instants at issue time so expiry survives an app restart.
class AuthTokens extends Equatable {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresAt,
    required this.refreshTokenExpiresAt,
  });

  factory AuthTokens.fromLifetimes({
    required String accessToken,
    required String refreshToken,
    required int accessTokenLifetimeSeconds,
    required int refreshTokenLifetimeSeconds,
    required DateTime issuedAt,
  }) {
    return AuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      accessTokenExpiresAt: issuedAt.add(
        Duration(seconds: accessTokenLifetimeSeconds),
      ),
      refreshTokenExpiresAt: issuedAt.add(
        Duration(seconds: refreshTokenLifetimeSeconds),
      ),
    );
  }

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      accessTokenExpiresAt: DateTime.parse(
        json['access_token_expires_at'] as String,
      ),
      refreshTokenExpiresAt: DateTime.parse(
        json['refresh_token_expires_at'] as String,
      ),
    );
  }

  final String accessToken;
  final String refreshToken;
  final DateTime accessTokenExpiresAt;
  final DateTime refreshTokenExpiresAt;

  /// Refresh slightly early so a call cannot start with a token that expires
  /// mid-flight.
  static const _refreshLeeway = Duration(seconds: 30);

  bool isAccessTokenExpired(DateTime now) =>
      !now.add(_refreshLeeway).isBefore(accessTokenExpiresAt);

  bool isRefreshTokenExpired(DateTime now) =>
      !now.isBefore(refreshTokenExpiresAt);

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'access_token_expires_at': accessTokenExpiresAt.toIso8601String(),
    'refresh_token_expires_at': refreshTokenExpiresAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    accessToken,
    refreshToken,
    accessTokenExpiresAt,
    refreshTokenExpiresAt,
  ];

  /// Deliberately redacted: token values must never reach logs.
  @override
  String toString() =>
      'AuthTokens(access: <redacted>, refresh: <redacted>, '
      'accessExpiresAt: $accessTokenExpiresAt)';
}

/// The authenticated user together with the organization they signed in to.
class Session extends Equatable {
  const Session({
    required this.userId,
    required this.name,
    required this.email,
    required this.orgId,
    required this.orgName,
    required this.role,
    this.avatarUrl,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      userId: json['user_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      orgId: json['org_id'] as String,
      orgName: json['org_name'] as String,
      role: OrgRole.fromWire(json['role'] as String),
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  final String userId;
  final String name;
  final String email;
  final String orgId;
  final String orgName;
  final OrgRole role;
  final String? avatarUrl;

  bool get isAdmin => role.isAdmin;

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'name': name,
    'email': email,
    'org_id': orgId,
    'org_name': orgName,
    'role': role.wireValue,
    'avatar_url': avatarUrl,
  };

  @override
  List<Object?> get props => [
    userId,
    name,
    email,
    orgId,
    orgName,
    role,
    avatarUrl,
  ];
}
