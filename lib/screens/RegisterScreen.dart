import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/AuthService.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  final AuthService _authService = AuthService();
  bool _isLoading = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF171023),
      body: SafeArea(
        child: Column(
          children: [
            // Geri butonu
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            // İçerik
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: SingleChildScrollView(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Hesap Oluştur',
                            style: GoogleFonts.sora(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sinema dünyasına adım atın',
                            style: GoogleFonts.sora(color: Colors.white54, fontSize: 14),
                          ),
                          const SizedBox(height: 24),

                          // Ad Soyad
                          _buildLabel('AD SOYAD'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: nameController,
                            style: GoogleFonts.sora(color: Colors.white),
                            decoration: _inputDecoration(
                              hint: 'Adınız ve soyadınız',
                              icon: Icons.person_outline,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // E-posta
                          _buildLabel('E-POSTA ADRESİ'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: emailController,
                            style: GoogleFonts.sora(color: Colors.white),
                            decoration: _inputDecoration(
                              hint: 'E-posta adresiniz',
                              icon: Icons.email_outlined,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Şifre
                          _buildLabel('ŞİFRE'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: passwordController,
                            obscureText: !isPasswordVisible,
                            style: GoogleFonts.sora(color: Colors.white),
                            decoration: _inputDecoration(
                              hint: 'Şifrenizi oluşturun',
                              icon: Icons.lock_outline,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.white54,
                                ),
                                onPressed: () {
                                  setState(() {
                                    isPasswordVisible = !isPasswordVisible;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'En az 8 karakter uzunluğunda olmalıdır.',
                              style: GoogleFonts.sora(color: Colors.white38, fontSize: 11),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildLabel('ŞİFRE TEKRAR'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: confirmPasswordController,
                            obscureText: !isConfirmPasswordVisible,
                            style: GoogleFonts.sora(color: Colors.white),
                            decoration: _inputDecoration(
                              hint: 'Şifrenizi tekrar girin',
                              icon: Icons.lock_outline,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.white54,
                                ),
                                onPressed: () {
                                  setState(() {
                                    isConfirmPasswordVisible = !isConfirmPasswordVisible;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Kayıt Ol butonu
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () async {
                                if (passwordController.text !=
                                    confirmPasswordController.text) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Şifreler eşleşmiyor'),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                  return;
                                }

                                setState(() {
                                  _isLoading = true;
                                });

                                final error = await _authService.register(
                                  nameController.text,
                                  emailController.text,
                                  passwordController.text,
                                );

                                if (!mounted) return;

                                setState(() {
                                  _isLoading = false;
                                });

                                if (!context.mounted) return;

                                if (error != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(error),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Kayıt başarılı! Giriş yapabilirsiniz.'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  Navigator.pop(context);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7C4DFF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                                  : Text(
                                'Kayıt Ol',
                                style: GoogleFonts.sora(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Alt satır
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Zaten hesabınız var mı? ',
                                style: GoogleFonts.sora(color: Colors.white54, fontSize: 13),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                                child: Text(
                                  'Giriş Yap',
                                  style: GoogleFonts.sora(
                                    color: const Color(0xFF7C4DFF),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tekrarlayan label yazısı için yardımcı fonksiyon
  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: GoogleFonts.sora(
          color: Colors.white54,
          fontSize: 11,
          letterSpacing: 1,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Tekrarlayan TextField dekorasyonu için yardımcı fonksiyon
  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.sora(color: Colors.white38),
      prefixIcon: Icon(icon, color: Colors.white54),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF7C4DFF)),
      ),
    );
  }
}