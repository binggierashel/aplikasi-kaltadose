import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/brand_mark.dart';
import '../core/widgets/notice_banner.dart';
import '../state/app_state_scope.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  String? _errorText;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _fillDemo(String username, String password) {
    setState(() {
      _usernameCtrl.text = username;
      _passwordCtrl.text = password;
      _errorText = null;
    });
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final state = AppStateScope.read(context);
    final res = state.login(_usernameCtrl.text, _passwordCtrl.text);
    if (!res.ok) {
      setState(() => _errorText = res.message);
    } else {
      setState(() => _errorText = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Botanical story header matching 01-login.png
              Container(
                color: AppColors.storyBg,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const KaltaFarmBrand(
                      iconSize: 44,
                      fontSize: 24,
                      textColor: AppColors.forest,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Nutrisi tepat.\nTanaman terawat.',
                      style: AppFonts.manrope(
                        fontSize: 29,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.1,
                        height: 1.18,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Pantau kondisi larutan dan kendalikan perangkat kebun melon Kalta Farm, dalam satu tempat.',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.55,
                        color: Color(0xFF536F5C),
                      ),
                    ),
                  ],
                ),
              ),

              // Login form section
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (state.sessionExpiredBanner != null) ...[
                      NoticeBanner(
                        text: state.sessionExpiredBanner!,
                        tone: NoticeTone.warning,
                      ),
                      const SizedBox(height: 18),
                    ],
                    Text(
                      'Selamat datang kembali',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Masuk untuk memantau dan mengelola perangkat.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 22),

                    // Username
                    Text('Username', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 7),
                    TextField(
                      controller: _usernameCtrl,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        hintText: 'Masukkan username',
                      ),
                      onChanged: (_) {
                        if (_errorText != null) {
                          setState(() => _errorText = null);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password
                    Text('Password', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 7),
                    TextField(
                      controller: _passwordCtrl,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        hintText: 'Masukkan password',
                        suffixIcon: IconButton(
                          tooltip: _obscure
                              ? 'Tampilkan password'
                              : 'Sembunyikan password',
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                            color: AppColors.ink,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      onChanged: (_) {
                        if (_errorText != null) {
                          setState(() => _errorText = null);
                        }
                      },
                    ),

                    if (_errorText != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorText!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Masuk ke aplikasi'),
                          SizedBox(width: 8),
                          Icon(Icons.chevron_right_rounded, size: 18),
                        ],
                      ),
                    ),

                    const SizedBox(height: 26),
                    const Divider(),
                    const SizedBox(height: 20),

                    Text(
                      'Coba aplikasi dengan akun simulasi',
                      style: theme.textTheme.labelSmall,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _fillDemo('owner', 'owner123'),
                            icon: const Icon(Icons.group_outlined, size: 17),
                            label: const Text('Owner'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _fillDemo('petani', 'petani123'),
                            icon: const Icon(Icons.eco_outlined, size: 17),
                            label: const Text('Petani'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Owner: owner / owner123 · Petani: petani / petani123\nMode simulasi lokal tersimpan di penyimpanan perangkat.',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
