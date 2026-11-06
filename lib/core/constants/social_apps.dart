/// Supported social apps: display name, every Android package that belongs to
/// the app, and the bundled brand logo.
class SocialApp {
  final String id;
  final String name;
  final List<String> packages;
  final String logo;

  /// Logo already is a full app tile (no white plate / padding needed).
  final bool fullBleed;

  const SocialApp({
    required this.id,
    required this.name,
    required this.packages,
    required this.logo,
    this.fullBleed = false,
  });

  String get mainPackage => packages.first;

  static const instagram = SocialApp(
    id: 'instagram',
    name: 'Instagram',
    packages: ['com.instagram.android'],
    logo: 'assets/images/apps/instagram.png',
    fullBleed: true,
  );
  static const tiktok = SocialApp(
    id: 'tiktok',
    name: 'TikTok',
    packages: ['com.zhiliaoapp.musically', 'com.ss.android.ugc.trill'],
    logo: 'assets/images/apps/tiktok.png',
  );
  static const youtube = SocialApp(
    id: 'youtube',
    name: 'YouTube',
    // Official app plus modified builds (Morphe, ReVanced, ReVanced Extended,
    // Vanced). Keep in sync with YouTubeApps.kt.
    packages: [
      'com.google.android.youtube',
      'app.morphe.android.youtube',
      'app.revanced.android.youtube',
      'app.rvx.android.youtube',
      'com.vanced.android.youtube',
    ],
    logo: 'assets/images/apps/youtube.png',
  );
  static const x = SocialApp(
    id: 'x',
    name: 'X',
    packages: ['com.twitter.android'],
    logo: 'assets/images/apps/x.png',
  );
  static const facebook = SocialApp(
    id: 'facebook',
    name: 'Facebook',
    packages: ['com.facebook.katana'],
    logo: 'assets/images/apps/facebook.png',
  );

  static const all = [instagram, tiktok, youtube, x, facebook];

  /// Finds the app a package belongs to (null for unknown packages).
  static SocialApp? forPackage(String pkg) {
    for (final a in all) {
      if (a.packages.contains(pkg)) return a;
    }
    return null;
  }
}
