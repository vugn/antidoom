# Google Play store listing

Copy-paste text for Play Console > Grow users > Store presence > Main store listing.
Limits: app name 30, short description 80, full description 4000 characters.
Rules followed: no third-party app names in the title or short description (Play
metadata policy), no rankings or "best", no emoji runs, ads and the purchase are
stated plainly, and the Accessibility use is explained.

Graphics already in this folder:

| Asset | File | Size |
| :--- | :--- | :--- |
| App icon | `brand/png/antidoom-icon-playstore-512.png` | 512 × 512 |
| Feature graphic | `docs/store/feature-graphic.png` | 1024 × 500 |
| Phone screenshots | `docs/store/screenshot-1…5-*.png` | 1080 × 1920 (9:16) |

---

## English (en-US, default)

### App name

```
AntiDoom: Stop Doomscrolling
```

### Short description

```
Counts every short video you watch, then helps you stop. Private, no account.
```

### Full description

```
AntiDoom counts the short videos you watch and steps in at a number you choose. A small counter sits on top of your feed, so you always know how many you've watched today.

WHAT IT DOES
• Counts videos, not swipes. AntiDoom recognises which video is on screen, so a swipe that bounces back, scrolling the comments or going back to a video you already saw doesn't count again.
• Floating counter. A small pill at the top of the feed shows today's count. Its expression goes from calm to tired to fried as the number climbs. It hides as soon as you leave the video feed, so profiles, messages and search stay out of its way.
• Check-ins. Every so many videos, a calm full-screen pause asks if the next one is still worth it: stop here, keep going, or snooze until tomorrow.
• Hard block, if you want it. Pick a number and the video feeds close for the rest of the day.
• A dashboard for today: videos watched, breaks taken and a per-app breakdown.

WORKS WITH
Short-video feeds in TikTok, Instagram Reels, YouTube Shorts, Facebook Reels and X. You choose which ones AntiDoom watches.

PRIVATE BY DESIGN
• No account and no sign-up.
• Your counts stay on your phone. AntiDoom has no server and never uploads what you watch.
• To tell videos apart it reads the creator name and caption of the video on screen and stores only a short hash of them, never the text. It does not read your messages, chats or anything you type.

WHY ACCESSIBILITY ACCESS
AntiDoom uses Android's Accessibility Service to notice when you are in a short-video feed, to tell one video from the next, and to draw the counter and the check-in screen over the feed. It is not used for anything else, and you can turn it off at any time in Settings.

ADS AND SUPPORT
This version is free and shows one small ad at the bottom of the dashboard. Ads never appear in the counter or in a check-in. Two optional one-time purchases: "Remove ads", or "Become a supporter", which also removes the ads and helps keep AntiDoom going. Every feature stays free either way. Ads are served by Google AdMob, which never sees what AntiDoom counts.

OPEN SOURCE
AntiDoom is free software under the GNU GPL v3. The code is public on GitHub, where you can also find an ad-free build. English and Bahasa Indonesia.

AntiDoom is not affiliated with TikTok, Instagram, YouTube, Facebook or X.
```

---

## Bahasa Indonesia (id-ID)

### Nama aplikasi

```
AntiDoom: Stop Doomscrolling
```

### Deskripsi singkat

```
Menghitung tiap video pendek yang kamu tonton, lalu bantu berhenti. Tanpa akun.
```

### Deskripsi lengkap

```
AntiDoom menghitung video pendek yang kamu tonton dan turun tangan di angka yang kamu pilih. Counter kecil muncul di atas feed, jadi kamu selalu tahu sudah berapa video hari ini.

YANG DILAKUKAN
• Menghitung video, bukan swipe. AntiDoom mengenali video mana yang sedang tampil, jadi swipe yang memantul balik, scroll komentar, atau kembali ke video yang sudah ditonton tidak dihitung lagi.
• Counter melayang. Pil kecil di atas feed menunjukkan jumlah hari ini. Ekspresinya berubah dari santai, capek, sampai gosong seiring angkanya naik. Counter langsung hilang saat kamu keluar dari feed video, jadi profil, pesan, dan pencarian tidak terhalang.
• Check-in. Setiap beberapa video, jeda layar penuh yang tenang bertanya apakah video berikutnya masih worth it: udahan, lanjut, atau tunda sampai besok.
• Blokir keras, kalau mau. Pilih angkanya dan feed video tertutup sampai besok.
• Dashboard hari ini: video yang ditonton, jeda yang diambil, dan rincian per aplikasi.

BISA DIPAKAI DI
Feed video pendek di TikTok, Instagram Reels, YouTube Shorts, Facebook Reels, dan X. Kamu yang memilih mana yang diawasi.

PRIVAT SEJAK AWAL
• Tanpa akun dan tanpa daftar.
• Hitunganmu tetap di HP. AntiDoom tidak punya server dan tidak pernah mengunggah apa yang kamu tonton.
• Untuk membedakan video, AntiDoom membaca nama kreator dan caption video yang sedang tampil, lalu hanya menyimpan hash pendeknya, bukan teksnya. AntiDoom tidak membaca pesan, chat, atau apa pun yang kamu ketik.

KENAPA BUTUH AKSES AKSESIBILITAS
AntiDoom memakai Layanan Aksesibilitas Android untuk mengetahui saat kamu berada di feed video pendek, membedakan satu video dengan berikutnya, dan menampilkan counter serta layar check-in di atas feed. Akses ini tidak dipakai untuk hal lain, dan bisa kamu matikan kapan saja di Pengaturan.

IKLAN DAN DUKUNGAN
Versi ini gratis dan menampilkan satu iklan kecil di bagian bawah dashboard. Iklan tidak pernah muncul di counter atau saat check-in. Ada dua pembelian sekali bayar yang opsional: "Hapus iklan", atau "Jadi supporter" yang juga menghapus iklan dan membantu AntiDoom terus berjalan. Semua fitur tetap gratis. Iklan disediakan oleh Google AdMob, yang tidak pernah melihat apa yang dihitung AntiDoom.

OPEN SOURCE
AntiDoom adalah perangkat lunak bebas berlisensi GNU GPL v3. Kodenya publik di GitHub, termasuk versi tanpa iklan. Tersedia dalam Bahasa Indonesia dan Inggris.

AntiDoom tidak berafiliasi dengan TikTok, Instagram, YouTube, Facebook, atau X.
```

---

## Before you submit (Play Console)

These are separate from the listing but block review if they're missing:

1. **Accessibility API declaration** (App content > Accessibility API). AntiDoom is not an
   accessibility tool, so Play needs the declaration form, a short screen recording of the
   feature, and an in-app prominent disclosure with explicit consent shown before the user
   is sent to the Accessibility settings.
2. **Foreground service type** (App content > Foreground service permissions): declare the
   `specialUse` service and why it must keep running.
3. **Data safety**: the Play build uses Google AdMob (advertising ID, device and app
   interaction data) and Play Billing (purchase history). The counts themselves are not
   collected.
4. **Ads**: answer "Yes, my app contains ads".
5. **Content rating** questionnaire and **target audience** (13+ fits a social-media
   companion app).
6. **In-app products** (one-time, non-consumable), then activate both:
   - `remove_ads`: "Remove ads"
   - `supporter`: "AntiDoom Supporter" (includes removing ads)
7. **Privacy policy URL**: `https://antidoom.app/privacy/`.
