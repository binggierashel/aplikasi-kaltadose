import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../core/widgets/brand_mark.dart';
import '../core/widgets/notice_banner.dart';
import '../state/app_state_scope.dart';
import 'activity_screen.dart';
import 'calibration_history_screen.dart';
import 'calibration_tds_screen.dart';
import 'control_screen.dart';
import 'dashboard_screen.dart';
import 'device_detail_screen.dart';
import 'device_form_screen.dart';
import 'devices_screen.dart';
import 'history_screen.dart';
import 'maintenance_screen.dart';
import 'menu_screen.dart';
import 'notifications_screen.dart';
import 'password_screen.dart';
import 'profile_edit_screen.dart';
import 'profile_screen.dart';
import 'thresholds_screen.dart';
import 'user_form_screen.dart';
import 'users_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _scrollController = ScrollController();

  String _page = 'dashboard';
  String? _editingDeviceId;
  int? _editingUserId;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _go(String next, {String? editDeviceId, int? editUserId}) {
    final state = AppStateScope.read(context);
    if (!state.isOwner &&
        const ['users', 'user-form', 'device-form'].contains(next)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Halaman ini hanya untuk Owner.')),
      );
      return;
    }

    setState(() {
      _page = next;
      _editingDeviceId = editDeviceId;
      _editingUserId = editUserId;
    });

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  int get _activeTabIndex {
    return switch (_page) {
      'dashboard' => 0,
      'devices' || 'detail' || 'device-form' => 1,
      'control' => 2,
      'history' => 3,
      _ => 4,
    };
  }

  Widget _buildBody() {
    final state = AppStateScope.of(context);
    // Guard if role switched while on an Owner-only screen
    if (!state.isOwner &&
        const ['users', 'user-form', 'device-form'].contains(_page)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _go('dashboard');
      });
    }

    return switch (_page) {
      'dashboard' => DashboardScreen(
          onOpenDetail: () => _go('detail'),
          onOpenHistory: () => _go('history'),
          onOpenControl: () => _go('control'),
        ),
      'devices' => DevicesScreen(
          onSelectAndGoDashboard: (id) {
            state.selectDevice(id);
            _go('dashboard');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Perangkat dipilih')),
            );
          },
          onOpenDetail: (id) {
            state.selectDevice(id);
            _go('detail');
          },
          onAddDevice: () => _go('device-form'),
          onEditDevice: (id) => _go('device-form', editDeviceId: id),
        ),
      'detail' => DeviceDetailScreen(
          onBack: () => _go('devices'),
          onEditDevice: (id) => _go('device-form', editDeviceId: id),
          onOpenDashboard: () => _go('dashboard'),
          onOpenControl: () => _go('control'),
          onOpenThresholds: () => _go('thresholds'),
          onOpenMaintenance: () => _go('maintenance'),
          onDeleted: () => _go('devices'),
        ),
      'device-form' => DeviceFormScreen(
          key: ValueKey('dev-form-${_editingDeviceId ?? 'new'}'),
          editingDeviceId: _editingDeviceId,
          onBack: () => _go('devices'),
          onSaved: () => _go('devices'),
        ),
      'control' => ControlScreen(
          onOpenThresholds: () => _go('thresholds'),
        ),
      'thresholds' => ThresholdsScreen(
          onCancel: () => _go('dashboard'),
        ),
      'maintenance' => MaintenanceScreen(
          onOpenCalibrationTds: () => _go('calibration-tds'),
          onOpenCalibrationHistory: () => _go('calibration-history'),
        ),
      'calibration-tds' => CalibrationTdsScreen(
          onBack: () => _go('maintenance'),
        ),
      'calibration-history' => CalibrationHistoryScreen(
          onBack: () => _go('maintenance'),
        ),
      'history' => const HistoryScreen(),
      'notifications' => NotificationsScreen(
          onOpenDeviceDetail: (id) {
            state.selectDevice(id);
            _go('detail');
          },
        ),
      'activity' => const ActivityScreen(),
      'users' => UsersScreen(
          onAddUser: () => _go('user-form'),
          onEditUser: (id) => _go('user-form', editUserId: id),
        ),
      'user-form' => UserFormScreen(
          key: ValueKey('user-form-${_editingUserId ?? 'new'}'),
          editingUserId: _editingUserId,
          onBack: () => _go('users'),
          onSaved: () => _go(state.isOwner ? 'users' : 'dashboard'),
        ),
      'profile' => ProfileScreen(
          onEditProfile: () => _go('profile-edit'),
          onChangePassword: () => _go('password'),
          onRoleSwitched: () => _go('dashboard'),
        ),
      'profile-edit' => ProfileEditScreen(
          onBack: () => _go('profile'),
          onSaved: () => _go('profile'),
        ),
      'password' => PasswordScreen(
          onBack: () => _go('profile'),
          onSaved: () => _go('profile'),
        ),
      'menu' => MenuScreen(
          onNavigate: (route) => _go(route),
        ),
      _ => DashboardScreen(
          onOpenDetail: () => _go('detail'),
          onOpenHistory: () => _go('history'),
          onOpenControl: () => _go('control'),
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final user = state.currentUser;
    if (user == null) return const SizedBox.shrink();

    final maintenanceDevices = state.maintenanceDevices;

    return PopScope(
      canPop: _page == 'dashboard',
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_page == 'calibration-tds' || _page == 'calibration-history') {
          _go('maintenance');
        } else if (_page == 'detail' || _page == 'device-form') {
          _go('devices');
        } else if (_page == 'user-form') {
          _go('users');
        } else if (_page == 'profile-edit' || _page == 'password') {
          _go('profile');
        } else {
          _go('dashboard');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.paper,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(76),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.white,
              border: Border(bottom: BorderSide(color: AppColors.line)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _go('dashboard'),
                        child: const KaltaFarmBrand(iconSize: 36, fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Notification bell
                    InkWell(
                      onTap: () => _go('notifications'),
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(
                              Icons.notifications_none_rounded,
                              size: 21,
                              color: AppColors.ink,
                            ),
                            if (state.unreadNotificationCount > 0)
                              Positioned(
                                right: 9,
                                top: 9,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.notifDot,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Avatar pill
                    InkWell(
                      onTap: () => _go('profile'),
                      borderRadius: BorderRadius.circular(22),
                      child: CircleAvatar(
                        radius: 21,
                        backgroundColor: AppColors.avatarBg,
                        child: Text(
                          AppFormatters.initials(user.name),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.forest,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (maintenanceDevices.isNotEmpty)
                MaintenanceGlobalBanner(
                  deviceNames: maintenanceDevices.map((d) => d.name).toList(),
                  onOpenMaintenance: () {
                    state.selectDevice(maintenanceDevices.first.id);
                    _go('maintenance');
                  },
                ),
              _buildBody(),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavTabButton(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Beranda',
                    active: _activeTabIndex == 0,
                    onTap: () => _go('dashboard'),
                  ),
                  _NavTabButton(
                    icon: Icons.memory_outlined,
                    activeIcon: Icons.memory_rounded,
                    label: 'Perangkat',
                    active: _activeTabIndex == 1,
                    onTap: () => _go('devices'),
                  ),
                  _NavTabButton(
                    icon: Icons.tune_outlined,
                    activeIcon: Icons.tune_rounded,
                    label: 'Kontrol',
                    active: _activeTabIndex == 2,
                    onTap: () => _go('control'),
                  ),
                  _NavTabButton(
                    icon: Icons.show_chart_rounded,
                    activeIcon: Icons.show_chart_rounded,
                    label: 'Riwayat',
                    active: _activeTabIndex == 3,
                    onTap: () => _go('history'),
                  ),
                  _NavTabButton(
                    icon: Icons.grid_view_outlined,
                    activeIcon: Icons.grid_view_rounded,
                    label: 'Menu',
                    active: _activeTabIndex == 4,
                    onTap: () => _go('menu'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTabButton extends StatelessWidget {
  const _NavTabButton({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.mint : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                active ? activeIcon : icon,
                size: 22,
                color: active ? AppColors.forest : AppColors.muted,
              ),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? AppColors.forest : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
