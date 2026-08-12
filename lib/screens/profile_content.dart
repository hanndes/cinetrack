import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../data/list_dao.dart';
import '../data/user_dao.dart';
import '../data/review_dao.dart';
import '../data/watched_dao.dart';
import '../services/current_user.dart';
import 'login_screen.dart';
import 'account_screen.dart';

class ProfileContent extends StatefulWidget {
  const ProfileContent({super.key});

  @override
  State<ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<ProfileContent> {
  final ListDao _listDao = ListDao();
  final UserDao _userDao = UserDao();
  final ReviewDao _reviewDao = ReviewDao();
  final WatchedDao _watchedDao = WatchedDao();

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile == null) return;

    final user = CurrentUser.instance.user;
    if (user?.id == null) return;

    // image_picker geçici cache klasörüne kaydediyor, cihaz bu klasörü
    // istediği zaman temizleyebilir. Bu yüzden dosyayı uygulamanın
    // kalıcı belgeler klasörüne kendimiz kopyalıyoruz.
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'profile_${user!.id}${p.extension(pickedFile.path)}';
    final savedImage = await File(pickedFile.path).copy(
      p.join(appDir.path, fileName),
    );

    // Veritabanına kalıcı yolu yaz
    await _userDao.updateProfileImage(user.id!, savedImage.path);

    // CurrentUser'daki user objesini de güncelle ki uygulama genelinde
    // güncel görsel kullanılsın
    CurrentUser.instance.setUser(user.copyWith(profileImageUrl: savedImage.path));

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = CurrentUser.instance.user?.profileImageUrl;
    final hasLocalImage = imagePath != null && File(imagePath).existsSync();

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 24),
          Center(
            child: Stack(
              children: [
                Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF7C4DFF), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C4DFF).withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: hasLocalImage
                        ? Image.file(
                      File(imagePath),
                      fit: BoxFit.cover,
                    )
                        : CachedNetworkImage(
                      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBcw_2ZcWdUXREuzusR9UBLTTbyXJvqKaSEwNAbarTC_GVdw--VFuOvTo0Vpu2R5MKMUc9eg5GKn-Mx12stQ2JWXgBadG-q7Y8YWzbtaEfx6u-0P9_JtPNKXxOn61JsilLhnkfQKHx9IE4msmC6PCayx0HtsBWPjdzj-2RpT58VgZyatGkPeYg4WjUzJS-ydYB85tgY8-ciI7pXWkxti05-IEbTXaYUZIPQQ7L237l7XSUw3lgYBzJN',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: const Color(0xFF241A33)),
                      errorWidget: (context, url, error) => const Icon(Icons.person, color: Colors.white24, size: 40),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFF7C4DFF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            CurrentUser.instance.user?.name ?? 'Misafir',
            style: GoogleFonts.sora(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            CurrentUser.instance.user?.email ?? '',
            style: GoogleFonts.manrope(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: 20),
          FutureBuilder<List<int>>(
            future: CurrentUser.instance.user?.id != null
                ? Future.wait([
              _watchedDao.getWatchedCount(CurrentUser.instance.user!.id!),
              _reviewDao.getReviewCountForUser(CurrentUser.instance.user!.id!),
              _listDao.getListCount(CurrentUser.instance.user!.id!),
            ])
                : Future.value([0, 0, 0]),
            builder: (context, snapshot) {
              final counts = snapshot.data ?? [0, 0, 0];
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStat(counts[0].toString(), 'WATCHED', const Color(0xFF7C4DFF)),
                  _buildDivider(),
                  _buildStat(counts[1].toString(), 'REVIEWS', const Color(0xFF00DCE5)),
                  _buildDivider(),
                  _buildStat(counts[2].toString(), 'LISTS', const Color(0xFFFFDB3C)),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: GoogleFonts.sora(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AccountScreen()),
                        ),
                        child: _buildSettingsTile(
                          icon: Icons.person,
                          iconColor: const Color(0xFF7C4DFF),
                          title: 'Account',
                          subtitle: 'Manage details and security',
                          showBorder: true,
                        ),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,

                        child: _buildSettingsTile(
                          icon: Icons.notifications,
                          iconColor: const Color(0xFF00DCE5),
                          title: 'Notification Settings',
                          subtitle: 'Alerts for new releases & activity',
                          showBorder: true,
                        ),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,

                        child: _buildSettingsTile(
                          icon: Icons.palette,
                          iconColor: const Color(0xFFFFDB3C),
                          title: 'App Preferences',
                          subtitle: 'Theme, language, and display',
                          showBorder: true,
                        ),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,

                        child: _buildSettingsTile(
                          icon: Icons.help,
                          iconColor: Colors.cyanAccent,
                          title: 'Help Center',
                          subtitle: 'FAQs and support',
                          showBorder: false,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              CurrentUser.instance.clear();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.logout, color: Colors.redAccent.shade100, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'LOG OUT',
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.redAccent.shade100,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

Widget _buildStat(String value, String label, Color color) {
  return Column(
    children: [
      Text(
        value,
        style: GoogleFonts.sora(color: color, fontSize: 24, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: GoogleFonts.jetBrainsMono(color: Colors.white70, fontSize: 10, letterSpacing: 1),
      ),
    ],
  );
}

Widget _buildDivider() {
  return Container(
    width: 1,
    height: 32,
    margin: const EdgeInsets.symmetric(horizontal: 24),
    color: Colors.white24,
  );
}

Widget _buildSettingsTile({
  required IconData icon,
  required Color iconColor,
  required String title,
  required String subtitle,
  required bool showBorder,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: showBorder
          ? const Border(bottom: BorderSide(color: Colors.white10))
          : null,
    ),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.manrope(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: Colors.white38),
      ],
    ),
  );
}