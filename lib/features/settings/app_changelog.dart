import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';

enum ChangeType { added, changed, fixed }

class ChangeItem {
  final ChangeType type;
  final String textEn;
  final String textId;

  const ChangeItem({
    required this.type,
    required this.textEn,
    required this.textId,
  });
}

class ReleaseEntry {
  final String version;
  final String dateEn;
  final String dateId;
  final bool isCurrent;
  final List<ChangeItem> changes;

  const ReleaseEntry({
    required this.version,
    required this.dateEn,
    required this.dateId,
    this.isCurrent = false,
    required this.changes,
  });
}

class AppChangelog {
  static const List<ReleaseEntry> releases = [
    ReleaseEntry(
      version: '0.11.2',
      dateEn: 'November 3, 2026',
      dateId: '3 November 2026',
      isCurrent: true,
      changes: [
        ChangeItem(
          type: ChangeType.fixed,
          textEn: 'Dynamic Versioning: Connected runtime version resolution via package_info_plus, eliminating stale version indicators and false-positive update alerts.',
          textId: 'Deteksi Versi Dinamis: Menghubungkan resolusi versi saat runtime via package_info_plus, menghilangkan tampilan versi usang dan peringatan pembaruan keliru.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '0.11.1',
      dateEn: 'November 3, 2026',
      dateId: '3 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Automated Flutter Widget Tests: Added UI widget test suite validating HomeScreen, RoutineScreen, and BillsScreen interactions.',
          textId: 'Uji Widget Otomatis: Menambahkan rangkaian pengujian UI widget untuk memastikan tampilan dan interaksi layar berjalan sempurna.',
        ),
        ChangeItem(
          type: ChangeType.fixed,
          textEn: 'Collision-Resistant UUIDs: Replaced microsecond timestamps with cryptographic UUID v4 for rock-solid record uniqueness across all modules.',
          textId: 'Identitas Unik Kriptografis (UUID): Mengganti ID berbasis mikrodetik dengan UUID v4 untuk mencegah tabrakan data saat sinkronisasi cloud.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '0.11.0',
      dateEn: 'November 3, 2026',
      dateId: '3 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Brand-New Cozy Landing Page: Warm, responsive web portal with interactive mobile phone stage, unified signature espresso & peach aesthetic, and direct APK download.',
          textId: 'Pembaruan Menyeluruh Landing Page: Tampilan web yang hangat dan responsif dengan mockup HP interaktif, estetika khas espresso & peach terpadu, dan tautan unduh APK.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Refreshed 3D House Mascot & App Icons: Updated all application launcher icons and brand badges across Android, iOS, Web, and Windows.',
          textId: 'Maskot Rumah 3D & Ikon Aplikasi Baru: Memperbarui seluruh ikon peluncur aplikasi di Android, iOS, Web, dan Windows dengan maskot 3D resmi.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '0.10.1',
      dateEn: 'November 3, 2026',
      dateId: '3 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.fixed,
          textEn: 'Firestore Security Hardening: Enforce ownership checks on username reservations, preventing cross-user updates and account takeover risks.',
          textId: 'Penguatan Keamanan Firestore: Menegakkan validasi kepemilikan UID pada reservasi username untuk mencegah pembajakan akun.',
        ),
        ChangeItem(
          type: ChangeType.fixed,
          textEn: 'Atomic Username Transactions: Integrated Firestore Transactions to prevent race conditions during sign-up and username changes.',
          textId: 'Transaksi Username Atomik: Transaksi Firestore untuk mencegah perebutan username bersamaan saat pendaftaran atau penggantian nama akun.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Design Token Standardization: Replaced all inline hardcoded hex colors with centralized AppColors palette tokens.',
          textId: 'Standarisasi Token Desain: Mengganti semua warna heksadesimal langsung dengan token palet AppColors terpusat.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '0.10.0',
      dateEn: 'November 3, 2026',
      dateId: '3 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Weekly Expense View: Switch seamlessly between monthly and weekly living expense views with custom 7-day ranges.',
          textId: 'Tampilan Pengeluaran Mingguan: Beralih mudah antara mode bulanan dan mingguan dengan kalkulasi otomatis 7 hari.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Live Real-Time Stream Sync: Instant two-way synchronization via Firestore snapshot listeners across active devices without manual refresh.',
          textId: 'Sinkronisasi Real-Time Live: Pembaruan dua arah instan via snapshot listener Firestore lintas perangkat tanpa perlu refresh manual.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '0.9.0',
      dateEn: 'November 3, 2026',
      dateId: '3 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Monthly Living Expense Overview & CSV Export: Complete financial pulse aggregating recurring bills, electricity token purchases, and laundry costs with CSV export and summary sharing.',
          textId: 'Ringkasan Pengeluaran Bulanan & Ekspor CSV: Fitur evaluasi finansial menyeluruh yang menghitung tagihan rutin, token listrik, dan laundry dengan opsi ekspor CSV.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Routine Completion History & Streak Insights: Track habit consistency with timestamped completion history and total counts for each cleaning routine.',
          textId: 'Riwayat Penyelesaian Rutinitas: Pantau konsistensi kebiasaan bersih-bersih dengan riwayat waktu dan total penyelesaian pada tiap rutinitas.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Shared Nest Code (House ID): Unique household code generated in user profile, preparing Nesty for multi-roommate & family live synchronization.',
          textId: 'Kode Rumah Bersama (Nest Code): Kode identitas rumah unik di profil pengguna untuk persiapan sinkronisasi data antar teman kos & keluarga.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Tactile Haptic Feedback: Satisfying haptic micro-interactions when checking off routines, replacing water gallons, and paying bills.',
          textId: 'Umpan Balik Haptik Taktil: Respon getaran mikro yang nyaman saat menandai rutinitas selesai, ganti galon, dan bayar tagihan.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '0.8.0',
      dateEn: 'November 3, 2026',
      dateId: '3 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Split Bill Calculation: Easily divide rent, internet, and utilities among roommates with live share preview and cozy badge indicators.',
          textId: 'Kalkulasi Bagi Tagihan: Bagi sewa kos, WiFi, dan utilitas bersama teman sekamar secara otomatis lengkap dengan pratinjau nominal per orang.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Automated Unit Test Suite: 18 unit tests validating calculation engines for electricity tokens, water gallons, bills cycle, and sync logic.',
          textId: 'Suite Pengujian Unit Otomatis: 18 tes unit memvalidasi engine prediksi token PLN, galon, siklus tagihan, dan sinkronisasi.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Disk Avatar Storage: Profile avatars are now saved directly as disk files, reducing app memory usage and eliminating XML SharedPreferences bloat.',
          textId: 'Penyimpanan Foto Profil di Disk: Foto profil kini disimpan ke file disk lokal, menghemat memori dan meniadakan penumpukan Base64 di SharedPreferences.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '0.7.2',
      dateEn: 'October 31, 2026',
      dateId: '31 Oktober 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.fixed,
          textEn: 'Deterministic Release Keystore: Integrated official release signing keystore into GitHub Actions CI, resolving Android signature mismatch conflicts during in-app updates.',
          textId: 'Kunci Rilis Deterministik: Mengintegrasikan keystore rilis resmi ke GitHub Actions CI, menuntaskan konflik tanda tangan Android saat pembaruan in-app.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '0.7.1',
      dateEn: 'October 31, 2026',
      dateId: '31 Oktober 2026',
      changes: [
        ChangeItem(
          type: ChangeType.fixed,
          textEn: 'Seamless Multi-Device Account Sync: Nicknames and profile photos are now fully mirrored into cloud storage and automatically synchronized across all your devices.',
          textId: 'Sinkronisasi Akun Lintas Perangkat: Nama panggilan dan foto profil kini tersinkronisasi penuh ke cloud dan otomatis tampil di semua perangkat.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Customizable Username: Edit and personalize your @username directly from Profile settings with real-time uniqueness validation.',
          textId: 'Kustomisasi Username: Ubah dan sesuaikan @username langsung dari Pengaturan Profil dengan validasi keunikan instan.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '0.7.0',
      dateEn: 'October 31, 2026',
      dateId: '31 Oktober 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'In-App GitHub Release Checker: Automatically checks for new APK updates from GitHub releases with direct one-tap download.',
          textId: 'Pemeriksa Rilis GitHub In-App: Otomatis memeriksa pembaruan APK dari rilis GitHub dengan tombol unduh langsung satu ketukan.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Dynamic Update Status & NEW Badge: Prompts when a newer version is ready and highlights update availability in Settings.',
          textId: 'Status Pembaruan Dinamis & Badge BARU: Memberitahu saat ada versi baru dan memunculkan badge indikator di Pengaturan.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Send Feedback & Issue Reporting: Quick access in Settings to submit bug reports and feature requests.',
          textId: 'Kirim Masukan & Laporan Masalah: Akses cepat di Pengaturan untuk mengirim laporan bug dan saran fitur.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '0.6.0',
      dateEn: 'October 31, 2026',
      dateId: '31 Oktober 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Full Home Management Suite: Electricity token tracker, water gallon predictor, laundry lifecycle tracker, and recurring bills.',
          textId: 'Suite Manajemen Rumah Lengkap: Pelacak token listrik, prediksi galon air, status penatu/laundry, dan tagihan rutin bulanan.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Bilingual 3-Screen Onboarding: Smooth introductory flow with cozy clay mascot illustrations and quick switch between English and Indonesian.',
          textId: 'Onboarding 3 Layar Bilingual: Alur perkenalan ramah dengan ilustrasi maskot clay dan tombol alih bahasa instan.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Cozy Clay Mascot Branding: Warm clay house icon, native splash screen, and responsive web landing page.',
          textId: 'Identitas Visual Maskot Cozy Clay: Ikon rumah clay hangat, splash screen asli, dan landing page web responsif.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '0.3.0',
      dateEn: 'October 31, 2026',
      dateId: '31 Oktober 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Dual Login with Username or Email: Sign in seamlessly using either your username or verified email address.',
          textId: 'Login Fleksibel dengan Username atau Email: Masuk akun menggunakan username maupun alamat email terdaftar.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Password Reset: Reset password link sent directly to your registered email address with one tap.',
          textId: 'Reset Kata Sandi: Kirim tautan reset kata sandi langsung ke email terdaftar hanya dengan satu ketukan.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Custom Profile & Photo: Set a personalized nickname and choose profile photo from gallery with cloud backup.',
          textId: 'Profil & Foto Khusus: Pasang nama panggilan dan unggah foto profil dari galeri yang tersinkron otomatis ke cloud.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Upgraded Settings Hub: Matching Wall o\' Pay layout with quick actions for Cloud Sync, Offline File Backup, Smart Reminders, and In-App Changelog.',
          textId: 'Pusat Pengaturan Terpadu: Menyesuaikan tata letak Wall o\' Pay dengan aksi Sinkronisasi Cloud, Cadangan File, Pengingat Pintar, dan Catatan Pembaruan.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '0.2.0',
      dateEn: 'October 31, 2026',
      dateId: '31 Oktober 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Firebase Authentication & Cloud Synchronization: Optional account backup and real-time cross-device sync.',
          textId: 'Autentikasi Firebase & Sinkronisasi Cloud: Cadangan akun dan sinkronisasi lintas perangkat.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Smart Reminders Engine: Timezone-aware local notifications for routine cleaning and supplies checking.',
          textId: 'Mesin Pengingat Pintar: Notifikasi lokal berbasis zona waktu untuk jadwal bersih-bersih dan cek stok.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Offline JSON Import & Export: Complete privacy-friendly offline backup and restore capabilities.',
          textId: 'Impor & Ekspor JSON Offline: Cadangkan dan pulihkan data secara offline tanpa memerlukan akun online.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '0.1.0',
      dateEn: 'October 25, 2026',
      dateId: '25 Oktober 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Initial Core Features: Daily supplies tracking (safe, low, out), recurring routines, electricity token, and water gallon cards.',
          textId: 'Fitur Inti Awal: Pelacakan stok harian (aman, menipis, habis), rutinitas berulang, kartu token listrik dan galon air.',
        ),
      ],
    ),
  ];
}

void showAppChangelogSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const AppChangelogSheet(),
  );
}

class AppChangelogSheet extends StatelessWidget {
  const AppChangelogSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = context.s;
    final isIndo = s.lang == 'id';

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.peach.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.history_edu_rounded, color: AppColors.brown),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.t('version_changelog'),
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          s.t('changelog_sub'),
                          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.brownSoft),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                itemCount: AppChangelog.releases.length,
                separatorBuilder: (_, __) => const SizedBox(height: 20),
                itemBuilder: (ctx, idx) {
                  final rel = AppChangelog.releases[idx];
                  return Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: rel.isCurrent ? AppColors.safe.withValues(alpha: 0.2) : theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: rel.isCurrent ? AppColors.safe : theme.colorScheme.outlineVariant,
                                  ),
                                ),
                                child: Text(
                                  'v${rel.version}${rel.isCurrent ? ' (Latest)' : ''}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: rel.isCurrent ? AppColors.safe : theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                isIndo ? rel.dateId : rel.dateEn,
                                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.brownSoft),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          for (final change in rel.changes) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _badge(change.type),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      isIndo ? change.textId : change.textEn,
                                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(ChangeType type) {
    final (label, color, bg) = switch (type) {
      ChangeType.added => ('ADDED', AppColors.safe, AppColors.safe.withValues(alpha: 0.15)),
      ChangeType.changed => ('CHANGED', AppColors.peach, AppColors.peach.withValues(alpha: 0.35)),
      ChangeType.fixed => ('FIXED', AppColors.low, AppColors.low.withValues(alpha: 0.2)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color),
      ),
    );
  }
}
