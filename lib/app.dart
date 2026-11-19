import 'package:material_ui/material_ui.dart';

import 'core/theme/app_theme.dart';
import 'core/widgets/brand_mark.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'state/app_state.dart';
import 'state/app_state_scope.dart';

class KaltaFarmApp extends StatefulWidget {
  const KaltaFarmApp({super.key, this.initialState});

  final AppState? initialState;

  @override
  State<KaltaFarmApp> createState() => _KaltaFarmAppState();
}

class _KaltaFarmAppState extends State<KaltaFarmApp> {
  late final AppState _state;
  late final bool _ownsState;

  @override
  void initState() {
    super.initState();
    if (widget.initialState != null) {
      _state = widget.initialState!;
      _ownsState = false;
    } else {
      _state = AppState();
      _ownsState = true;
      _state.init();
    }
  }

  @override
  void dispose() {
    if (_ownsState) {
      _state.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      state: _state,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _state.recordUserInteraction(),
        child: MaterialApp(
          title: 'Kalta Dose · Smart Autodosing',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build(),
          home: AnimatedBuilder(
            animation: _state,
            builder: (context, _) {
              if (!_state.initialized) {
                return const Scaffold(
                  backgroundColor: AppColors.paper,
                  body: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        KaltaFarmBrand(iconSize: 42, fontSize: 25),
                        SizedBox(height: 18),
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.forest,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return _state.isLoggedIn
                  ? const MainShell()
                  : const LoginScreen();
            },
          ),
        ),
      ),
    );
  }
}
