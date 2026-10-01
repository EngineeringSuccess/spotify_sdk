/// The result of authorizing Spotify with PKCE.
class SpotifyAuthorizationResult {
  /// Creates an authorization result.
  const SpotifyAuthorizationResult({
    this.authorizationCode,
    this.codeVerifier,
    this.accessToken,
    this.refreshToken,
    this.expiresAt,
  });

  /// Creates an authorization result from a platform-channel map.
  factory SpotifyAuthorizationResult.fromMap(Map<dynamic, dynamic> map) =>
      SpotifyAuthorizationResult(
        authorizationCode: map['authorizationCode'] as String?,
        codeVerifier: map['codeVerifier'] as String?,
        accessToken: map['accessToken'] as String?,
        refreshToken: map['refreshToken'] as String?,
        expiresAt: (map['expiresAt'] as num?)?.toDouble(),
      );

  /// The authorization code returned on Android.
  final String? authorizationCode;

  /// The PKCE verifier generated on Android.
  final String? codeVerifier;

  /// The access token returned on iOS.
  final String? accessToken;

  /// The refresh token returned on iOS.
  final String? refreshToken;

  /// The token expiration time in seconds since the Unix epoch.
  final double? expiresAt;

  /// Whether this result contains an authorization code.
  bool get isAuthorizationCode => authorizationCode != null;

  /// Whether this result contains an access token.
  bool get isTokenResult => accessToken != null;
}
