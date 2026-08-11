import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/user_dao.dart';
import '../data/review_dao.dart';
import '../data/list_dao.dart';
import '../data/watchlist_dao.dart';
import '../services/current_user.dart';
import 'LoginScreen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final UserDao _userDao = UserDao();
  final ReviewDao _reviewDao = ReviewDao();
  final ListDao _listDao = ListDao();
  final WatchlistDao _watchlistDao = WatchlistDao();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isSaving = false;
  bool _isChangingPassword = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  late Future<_AccountStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    final user = CurrentUser.instance.user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _statsFuture = _loadStats();
  }

  Future<_AccountStats> _loadStats() async {
    final userId = CurrentUser.instance.user?.id;
    if (userId == null) {
      return const _AccountStats(reviewCount: 0, listCount: 0, watchlistCount: 0);
    }

    final results = await Future.wait([
      _reviewDao.getReviewCountForUser(userId),
      _listDao.getListCount(userId),
      _watchlistDao.getWatchlistCount(userId),
    ]);

    return _AccountStats(
      reviewCount: results[0],
      listCount: results[1],
      watchlistCount: results[2],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = CurrentUser.instance.user;
    if (user?.id == null) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İsim ve e-posta boş bırakılamaz'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    await _userDao.updateProfile(user!.id!, name, email);
    CurrentUser.instance.setUser(user.copyWith(name: name, email: email));

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bilgiler güncellendi'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _changePassword() async {
    final user = CurrentUser.instance.user;
    if (user?.id == null) return;

    final current = _currentPasswordController.text;
    final newPass = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tüm şifre alanlarını doldur'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (newPass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yeni şifre en az 6 karakter olmalı'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (newPass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yeni şifreler eşleşmiyor'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isChangingPassword = true);

    final success = await _userDao.changePassword(user!.id!, current, newPass);

    if (!mounted) return;
    setState(() => _isChangingPassword = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mevcut şifre yanlış'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Şifre değiştirildi'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1730),
          title: Text(
            'Hesabı Sil',
            style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Hesabını silmek üzeresin. Tüm yorumların, listelerin ve watchlist\'in kalıcı olarak silinecek. Bu işlem geri alınamaz.',
            style: GoogleFonts.manrope(color: Colors.white70, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('İptal', style: GoogleFonts.manrope(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                'Hesabı Sil',
                style: GoogleFonts.manrope(color: Colors.redAccent, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final user = CurrentUser.instance.user;
    if (user?.id == null) return;

    await _userDao.deleteAccount(user!.id!);
    CurrentUser.instance.clear();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }

  InputDecoration _fieldDecoration({String? label, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.manrope(color: Colors.white54),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF7C4DFF)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.sora(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF171023),
      appBar: AppBar(
        backgroundColor: const Color(0xFF171023),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Account',
          style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildStatsCard(),
          const SizedBox(height: 28),
          _sectionTitle('Profil Bilgileri'),
          const SizedBox(height: 16),
          Text(
            'İsim',
            style: GoogleFonts.manrope(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            style: GoogleFonts.manrope(color: Colors.white),
            decoration: _fieldDecoration(),
          ),
          const SizedBox(height: 20),
          Text(
            'E-posta',
            style: GoogleFonts.manrope(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.manrope(color: Colors.white),
            decoration: _fieldDecoration(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C4DFF),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
                  : Text(
                'Bilgileri Kaydet',
                style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),

          const SizedBox(height: 36),
          const Divider(color: Colors.white10),
          const SizedBox(height: 20),

          _sectionTitle('Şifre Değiştir'),
          const SizedBox(height: 16),
          TextField(
            controller: _currentPasswordController,
            obscureText: _obscureCurrent,
            style: GoogleFonts.manrope(color: Colors.white),
            decoration: _fieldDecoration(
              label: 'Mevcut Şifre',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureCurrent ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white38,
                ),
                onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _newPasswordController,
            obscureText: _obscureNew,
            style: GoogleFonts.manrope(color: Colors.white),
            decoration: _fieldDecoration(
              label: 'Yeni Şifre',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNew ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white38,
                ),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirm,
            style: GoogleFonts.manrope(color: Colors.white),
            decoration: _fieldDecoration(
              label: 'Yeni Şifre (Tekrar)',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white38,
                ),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _isChangingPassword ? null : _changePassword,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFF7C4DFF)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isChangingPassword
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Color(0xFF7C4DFF), strokeWidth: 2),
              )
                  : Text(
                'Şifreyi Değiştir',
                style: GoogleFonts.sora(color: const Color(0xFF7C4DFF), fontWeight: FontWeight.w700),
              ),
            ),
          ),

          const SizedBox(height: 36),
          const Divider(color: Colors.white10),
          const SizedBox(height: 20),

          _sectionTitle('Tehlikeli Bölge'),
          const SizedBox(height: 12),
          Text(
            'Hesabını sildiğinde tüm yorumların, listelerin ve watchlist\'in kalıcı olarak silinir.',
            style: GoogleFonts.manrope(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _confirmDeleteAccount,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.redAccent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Hesabı Sil',
                style: GoogleFonts.sora(color: Colors.redAccent, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return FutureBuilder<_AccountStats>(
      future: _statsFuture,
      builder: (context, snapshot) {
        final stats = snapshot.data;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatItem(
                value: stats?.reviewCount,
                label: 'YORUM',
                color: const Color(0xFF00DCE5),
              ),
              _buildStatDivider(),
              _buildStatItem(
                value: stats?.listCount,
                label: 'LİSTE',
                color: const Color(0xFFFFDB3C),
              ),
              _buildStatDivider(),
              _buildStatItem(
                value: stats?.watchlistCount,
                label: 'WATCHLIST',
                color: const Color(0xFF7C4DFF),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem({required int? value, required String label, required Color color}) {
    return Expanded(
      child: Column(
        children: [
          value == null
              ? SizedBox(
            height: 26,
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              ),
            ),
          )
              : Text(
            value.toString(),
            style: GoogleFonts.sora(color: color, fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(color: Colors.white70, fontSize: 10, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 32,
      color: Colors.white24,
    );
  }
}

class _AccountStats {
  final int reviewCount;
  final int listCount;
  final int watchlistCount;

  const _AccountStats({
    required this.reviewCount,
    required this.listCount,
    required this.watchlistCount,
  });
}