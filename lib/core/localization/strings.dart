import 'package:flutter/widgets.dart';

/// Short, plain-language UI copy for the redesigned screens (EN / ID).
class S {
  final bool _id;
  const S(this._id);

  String _t(String en, String id) => _id ? id : en;

  // Home
  String get protectionOn => _t('Protection is on', 'Proteksi aktif');
  String get protectionOff => _t('Protection is off', 'Proteksi mati');
  String watchingApps(int n) =>
      _t('Watching $n ${n == 1 ? 'app' : 'apps'}', 'Memantau $n aplikasi');
  String get turnOnHint =>
      _t('Turn on to start counting', 'Nyalakan untuk mulai menghitung');
  String sessionOf(int max) => _t('of $max', 'dari $max');
  String get sessionCaption => _t('swipes in a row', 'swipe berturut-turut');
  String breakExplainer(int max) => _t(
        'A break screen appears after $max swipes in a row.',
        'Layar istirahat muncul setelah $max swipe berturut-turut.',
      );
  String get statToday => _t('Today', 'Hari ini');
  String get statBreaks => _t('Breaks', 'Istirahat');
  String get statSaved => _t('Saved', 'Dihemat');
  String minutesShort(int m) => _t('${m}m', '$m mnt');
  String get swipesToday => _t('Swipes today', 'Swipe hari ini');
  String get notInstalled => _t('Not installed', 'Tidak terpasang');
  String get paused => _t('Off', 'Mati');
  String get setupTitle => _t('Finish setup', 'Selesaikan pengaturan');
  String get setupDesc => _t(
        'AntiDoom needs permission to see when you scroll.',
        'AntiDoom butuh izin untuk tahu saat kamu scroll.',
      );
  String get continueBtn => _t('Continue', 'Lanjut');

  // Settings
  String get settingsTitle => _t('Settings', 'Pengaturan');
  String get breakAfter => _t('Break after', 'Istirahat setelah');
  String get swipesUnit => _t('swipes', 'swipe');
  String get breakAfterHint => _t(
        'Counts swipes in Reels, Shorts and TikTok. Resets when you leave the app.',
        'Menghitung swipe di Reels, Shorts, dan TikTok. Reset saat kamu keluar dari aplikasi.',
      );
  String get appsToWatch => _t('Apps to watch', 'Aplikasi yang dipantau');
  String get floatingCounter => _t('Floating counter', 'Penghitung melayang');
  String get floatingCounterHint => _t(
        'A small counter on screen while you scroll.',
        'Penghitung kecil di layar saat kamu scroll.',
      );
  String get language => _t('Language', 'Bahasa');
  String get languageName => _t('English', 'Bahasa Indonesia');
  String get permissions => _t('Permissions', 'Izin');
  String get allSet => _t('All set', 'Lengkap');
  String get needsAction => _t('Needs action', 'Perlu tindakan');
  String get previewBreak => _t('Preview break screen', 'Lihat layar istirahat');
  String get simulateSwipe => _t('Simulate a swipe', 'Simulasi swipe');
  String get general => _t('General', 'Umum');
  String get privacyNote => _t(
        'Everything stays on your phone. AntiDoom never reads your messages or uploads anything.',
        'Semua data tetap di HP kamu. AntiDoom tidak membaca pesan atau mengunggah apa pun.',
      );
  /// Play build: the counting is still local, but ads need the network.
  String get privacyNotePlay => _t(
        'Your counts stay on your phone and AntiDoom never reads your messages. '
            'Ads come from Google AdMob and never see what you count.',
        'Hitunganmu tetap di HP kamu dan AntiDoom tidak membaca pesan. '
            'Iklan datang dari Google AdMob dan tidak pernah melihat apa yang kamu hitung.',
      );

  // About
  String get about => _t('About', 'Tentang');
  String openSourceDesc(String license) => _t(
        'Free and open source under the $license license.',
        'Gratis dan open source dengan lisensi $license.',
      );
  String get viewOnGithub => _t('View on GitHub', 'Lihat di GitHub');
  String get licenses => _t('Licenses', 'Lisensi');
  String get licensesDesc =>
      _t('AntiDoom and the libraries it uses', 'AntiDoom dan library yang dipakai');

  // Setup
  String get setupScreenTitle => _t('Set up AntiDoom', 'Atur AntiDoom');
  String get setupScreenDesc => _t(
        'Two quick steps so AntiDoom can count your swipes.',
        'Dua langkah singkat agar AntiDoom bisa menghitung swipe kamu.',
      );
  String get stepAccessTitle => _t('Allow accessibility', 'Izinkan aksesibilitas');
  String get stepAccessDesc => _t(
        'Lets AntiDoom notice swipes in short-video apps.',
        'Agar AntiDoom bisa mendeteksi swipe di aplikasi video pendek.',
      );
  String get stepBatteryTitle =>
      _t('Keep it running', 'Biarkan tetap berjalan');
  String get stepBatteryDesc => _t(
        'Stops your phone from closing AntiDoom in the background.',
        'Agar HP tidak menutup AntiDoom di latar belakang.',
      );
  String get allowBtn => _t('Allow', 'Izinkan');
  String get doneLabel => _t('Done', 'Selesai');
  String get getStarted => _t('Get started', 'Mulai');
  String get skipForNow => _t('Skip for now', 'Lewati dulu');

  // Limits (home + settings)
  String get swipesTodayCaption => _t('swipes today', 'swipe hari ini');
  String nextCheckIn(int n) => _t('Next check-in at $n', 'Check-in berikutnya di $n');
  String explainWarn(int every) => _t(
        "You'll get a check-in every $every swipes.",
        'Kamu akan dapat check-in setiap $every swipe.',
      );
  String explainBlock(int n, int warnEvery) => warnEvery > 0
      ? _t('Check-in every $warnEvery swipes. Feeds lock at $n.',
          'Check-in setiap $warnEvery swipe. Feed terkunci di $n.')
      : _t('Feeds lock after $n swipes today.',
          'Feed terkunci setelah $n swipe hari ini.');
  String get explainCountOnly => _t(
        'Just counting. No check-ins or blocks.',
        'Hanya menghitung. Tanpa check-in atau blokir.',
      );
  String get blockedToday => _t('Blocked until tomorrow', 'Diblokir sampai besok');
  String get whenToStop => _t('When to stop', 'Kapan berhenti');
  String get checkInTitle => _t('Check-ins', 'Check-in');
  String get checkInEveryLabel => _t('Check in every', 'Check-in setiap');
  String get blockAfterRow => _t('Block after', 'Blokir setelah');
  String swipesValue(int n) => _t('$n swipes', '$n swipe');
  String get checkInSheetTitle =>
      _t('Check in every how many swipes?', 'Check-in setiap berapa swipe?');
  String get checkInSheetHint => _t(
        'A break screen asks if you want to keep going each time you reach this many swipes.',
        'Setiap kelipatan angka ini, layar istirahat bertanya apakah kamu mau lanjut.',
      );
  String get invalidCheckIn =>
      _t('Enter a number from 10 to 1000', 'Masukkan angka 10 sampai 1000');
  String get snoozedTitle => _t('Snoozed for today', 'Dijeda sampai besok');
  String get snoozedDesc => _t(
        'Check-ins and blocks are off until tomorrow.',
        'Check-in dan blokir mati sampai besok.',
      );
  String get resumeBtn => _t('Resume', 'Lanjutkan');
  String get checkInEveryField => _t('Remind me every', 'Ingatkan setiap');
  String get checkInDesc =>
      _t('You decide: keep going or stop.', 'Kamu yang putuskan: lanjut atau berhenti.');
  String get hardBlockTitle => _t('Hard block', 'Blokir paksa');
  String get hardBlockDesc =>
      _t('Locks feeds until tomorrow.', 'Kunci feed sampai besok.');
  String hardBlockOn(int n) =>
      _t('Feeds lock after $n swipes today', 'Feed terkunci setelah $n swipe hari ini');
  String get hardBlockSheetTitle =>
      _t('Block after how many swipes?', 'Blokir setelah berapa swipe?');
  String get hardBlockSheetHint => _t(
        'Once you reach this number, short-video feeds stay locked until tomorrow.',
        'Setelah angka ini tercapai, feed video pendek terkunci sampai besok.',
      );
  String get save => _t('Save', 'Simpan');
  String get invalidNumber =>
      _t('Enter a number from 10 to 5000', 'Masukkan angka 10 sampai 5000');

  // First-run setup flow
  String stepOf(int i, int n) => _t('Step $i of $n', 'Langkah $i dari $n');
  String get obLangTitle => _t('Choose your language', 'Pilih bahasa');
  String get obLangDesc =>
      _t('You can change this later in Settings.', 'Bisa diganti nanti di Pengaturan.');
  String get obAppsTitle =>
      _t('Which apps pull you in?', 'Aplikasi mana yang bikin kamu lupa waktu?');
  String get obAppsDesc => _t(
        'AntiDoom only counts swipes in the apps you pick.',
        'AntiDoom hanya menghitung swipe di aplikasi yang kamu pilih.',
      );
  String get obModeTitle =>
      _t('How should AntiDoom stop you?', 'Gimana AntiDoom menghentikanmu?');
  String get obModeDesc =>
      _t('Pick one. You can change it any time.', 'Pilih satu. Bisa diganti kapan saja.');
  String get modeWarnTitle => _t('Check in with me', 'Ingatkan aku');
  String get modeWarnDesc => _t(
        'Every few swipes, choose to keep going or stop.',
        'Setiap beberapa swipe, pilih lanjut atau berhenti.',
      );
  String get modeBlockTitle => _t('Block me', 'Blokir aku');
  String get modeBlockDesc => _t(
        'Feeds lock for the rest of the day at a number you choose.',
        'Feed terkunci sampai besok di angka yang kamu pilih.',
      );
  String get blockAfterLabel => _t('Block after', 'Blokir setelah');
  String modeBlockNote(int every) => _t(
        'You still get a check-in every $every swipes before that.',
        'Kamu tetap dapat check-in setiap $every swipe sebelum itu.',
      );
  String get obPermTitle => _t('Last step: permissions', 'Langkah terakhir: izin');
  String get startBtn => _t('Start AntiDoom', 'Mulai AntiDoom');

  // Support (Google Play build)
  String get support => _t('Support AntiDoom', 'Dukung AntiDoom');
  String get removeAds => _t('Remove ads', 'Hapus iklan');
  String removeAdsDesc(String? price) => price == null
      ? _t('One-time purchase', 'Sekali bayar')
      : _t('One-time purchase · $price', 'Sekali bayar · $price');
  String get adsRemovedTitle => _t('Ads removed', 'Iklan sudah dihapus');
  String get adsRemovedDesc =>
      _t('Thanks for supporting AntiDoom.', 'Terima kasih sudah mendukung AntiDoom.');
  String get purchasePending =>
      _t('Waiting for Google Play…', 'Menunggu Google Play…');
  String get purchaseFailed => _t(
        "That didn't go through. Tap to try again.",
        'Pembelian gagal. Ketuk untuk coba lagi.',
      );
  String get restorePurchase => _t('Restore purchase', 'Pulihkan pembelian');
}

extension StringsContext on BuildContext {
  S get s => S(Localizations.localeOf(this).languageCode == 'id');
}
