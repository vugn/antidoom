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
        'A few quick steps so AntiDoom can count your swipes and keep running.',
        'Beberapa langkah singkat agar AntiDoom bisa menghitung swipe dan tetap berjalan.',
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
  String get stepAutostartTitle => _t('Allow auto-start', 'Izinkan mulai otomatis');
  String get stepAutostartDesc => _t(
        'Brings AntiDoom back after you close it or restart your phone. Find AntiDoom in the list and switch it on.',
        'Agar AntiDoom jalan lagi setelah ditutup atau HP dinyalakan ulang. Cari AntiDoom di daftar lalu nyalakan.',
      );
  String get stepPopupTitle =>
      _t('Allow background pop-ups', 'Izinkan pop-up di latar belakang');
  // HyperOS calls it "Open new windows while running in the background";
  // older MIUI says "Display pop-up windows…". Both live under Other permissions.
  String get stepPopupDesc => _t(
        'Lets the break screen open AntiDoom while another app is open. Under "Other permissions", allow opening new windows (pop-ups) while running in the background.',
        'Agar layar istirahat bisa membuka AntiDoom saat app lain sedang terbuka. Di "Izin lainnya", izinkan membuka jendela baru (pop-up) saat berjalan di latar belakang.',
      );
  String get oemConfirmTitle => _t('Did you switch it on?', 'Sudah dinyalakan?');
  String get oemConfirmBody => _t(
        "Your phone doesn't let AntiDoom check this setting, so we'll take your word for it.",
        'HP kamu tidak mengizinkan AntiDoom mengecek pengaturan ini, jadi kami ikut jawabanmu.',
      );
  String get oemConfirmYes => _t("Yes, it's on", 'Sudah');
  String get oemConfirmNo => _t('Not yet', 'Belum');
  String get oemOpenFailed => _t(
        "Couldn't open that screen. Open Settings > Apps > AntiDoom and look for it there.",
        'Layar itu tidak bisa dibuka. Buka Pengaturan > Aplikasi > AntiDoom dan cari di sana.',
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

  // Accessibility disclosure (Google Play prominent disclosure + consent)
  String get a11yDisclosureTitle =>
      _t('Before you turn on Accessibility', 'Sebelum menyalakan Aksesibilitas');
  String get a11yDisclosureIntro => _t(
        "AntiDoom uses Android's Accessibility Service to count short videos. Here is exactly what it does with it.",
        'AntiDoom memakai Layanan Aksesibilitas Android untuk menghitung video pendek. Ini persis apa yang dilakukannya.',
      );
  String get a11yReadsTitle => _t('What it reads', 'Yang dibaca');
  String get a11yReadsBody => _t(
        'Only in the short-video apps you picked (TikTok, Instagram, YouTube, Facebook, X): which screen is open, and the creator name and caption of the video on screen.',
        'Hanya di aplikasi video pendek yang kamu pilih (TikTok, Instagram, YouTube, Facebook, X): layar mana yang terbuka, serta nama kreator dan caption video yang sedang tampil.',
      );
  String get a11yWhyTitle => _t('Why', 'Untuk apa');
  String get a11yWhyBody => _t(
        'To know when you are in a video feed, to recognise each video so it is counted once, and to show the counter, check-ins and block screen on top of the feed.',
        'Untuk mengetahui saat kamu di feed video, mengenali tiap video agar dihitung sekali, dan menampilkan counter, check-in, serta layar blokir di atas feed.',
      );
  String get a11yPrivateTitle => _t('What stays private', 'Yang tetap privat');
  String get a11yPrivateBody => _t(
        'Everything is processed on your phone. Only a short hash of each video is kept, never the text, and nothing is sent anywhere. It never reads your messages, chats or what you type.',
        'Semuanya diproses di HP kamu. Hanya hash pendek tiap video yang disimpan, bukan teksnya, dan tidak ada yang dikirim ke mana pun. AntiDoom tidak pernah membaca pesan, chat, atau apa yang kamu ketik.',
      );
  String get a11yControlTitle => _t("You're in control", 'Kamu yang pegang kendali');
  String get a11yControlBody => _t(
        'You can turn it off any time in Android Settings > Accessibility. Without it, AntiDoom cannot count videos.',
        'Kamu bisa mematikannya kapan saja di Pengaturan Android > Aksesibilitas. Tanpa ini, AntiDoom tidak bisa menghitung video.',
      );
  String get a11yAgree => _t('Agree and continue', 'Setuju dan lanjutkan');
  String get a11yDecline => _t('No thanks', 'Jangan sekarang');

  // Support (Google Play build)
  String get support => _t('Support AntiDoom', 'Dukung AntiDoom');
  String get becomeSupporter => _t('Become a supporter', 'Jadi supporter');
  String supporterDesc(String? price) => price == null
      ? _t('One-time · keeps AntiDoom going · no ads', 'Sekali bayar · bantu AntiDoom terus jalan · tanpa iklan')
      : _t('One-time $price · keeps AntiDoom going · no ads',
          'Sekali bayar $price · bantu AntiDoom terus jalan · tanpa iklan');
  String get supporterThanksTitle => _t("You're a supporter", 'Kamu supporter AntiDoom');
  String get supporterThanksDesc => _t(
        'Thank you. Ads are gone and you keep this project alive.',
        'Terima kasih. Iklan sudah hilang dan kamu ikut menjaga project ini tetap hidup.',
      );
  String get supporterBadge => _t('Supporter', 'Supporter');
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

  // Occasional thank-you (Google Play build)
  String get thanksTitle => _t('Thanks for using AntiDoom', 'Terima kasih sudah pakai AntiDoom');
  String get thanksBody => _t(
        "AntiDoom is free and open source, built by one person. If it's helping you look up more often, you can chip in. Totally optional.",
        'AntiDoom gratis dan open source, dibuat oleh satu orang. Kalau AntiDoom membantumu lebih sering lihat sekitar, kamu bisa ikut dukung. Sepenuhnya opsional.',
      );
  String thanksSupport(String? price) => price == null
      ? _t('Support AntiDoom', 'Dukung AntiDoom')
      : _t('Support AntiDoom · $price', 'Dukung AntiDoom · $price');
  String thanksRemoveAds(String? price) =>
      price == null ? _t('Remove ads', 'Hapus iklan') : _t('Remove ads · $price', 'Hapus iklan · $price');
  String get thanksLater => _t('Not now, keep using AntiDoom', 'Nanti saja, lanjut pakai AntiDoom');
  String get thanksFreeNote => _t(
        'Counting, check-ins and blocks stay free for everyone.',
        'Menghitung, check-in, dan blokir tetap gratis untuk semua.',
      );
  String get thanksDoneTitle => _t('You made our day', 'Kamu bikin hari kami');
  String get thanksDoneBody => _t(
        'Thank you for supporting AntiDoom. Now go look up.',
        'Terima kasih sudah mendukung AntiDoom. Sekarang, yuk lihat sekitar.',
      );
  String get thanksDoneClose => _t('Back to AntiDoom', 'Kembali ke AntiDoom');
}

extension StringsContext on BuildContext {
  S get s => S(Localizations.localeOf(this).languageCode == 'id');
}
