import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/schedule_provider.dart';
import '../../core/providers/booking_provider.dart';
import '../../core/models/user.dart';
import '../schedules/schedule_calendar_screen.dart';
import '../bookings/booking_list_screen.dart';
import '../users/user_list_screen.dart';
import '../instructors/instructor_list_screen.dart';
import '../admin/class_type_management_screen.dart';
import '../admin/membership_template_management_screen.dart';
import '../../core/api/api_client.dart';

Color _parseColorString(String colorString, Color defaultColor) {
  try {
    String cleanedColor = colorString.replaceAll('#', '');
    if (cleanedColor.length == 6) {
      return Color(int.parse('0xFF$cleanedColor'));
    }
    return defaultColor;
  } catch (e) {
    return defaultColor;
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final GlobalKey<UserListScreenState> _userListKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      context.read<ScheduleProvider>().loadSchedules(),
      context.read<ScheduleProvider>().loadClassTypes(),
      context.read<BookingProvider>().loadBookings(),
    ]);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // 회원 탭으로 이동할 때 자동 새로고침
    if (index == 3) {
      _userListKey.currentState?.loadUsers();
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
            },
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.user!;
        
        return Scaffold(
          appBar: AppBar(
            title: Text(_getPageTitle(_selectedIndex)),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      '${user.displayRole} · ${user.name}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: _logout,
                      tooltip: '로그아웃',
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              _DashboardHome(user: user, onNavigate: _onItemTapped),
              const ScheduleCalendarScreen(),
              const BookingListScreen(),
              if (user.isMaster || user.isInstructor) UserListScreen(key: _userListKey),
              if (user.isMaster) const InstructorListScreen(),
              if (user.isMaster) const ClassTypeManagementScreen(),
              if (user.isMaster) const MembershipTemplateManagementScreen(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: '홈',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.schedule),
                label: '스케줄',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.book),
                label: '예약',
              ),
              if (user.isMaster || user.isInstructor)
                const BottomNavigationBarItem(
                  icon: Icon(Icons.people),
                  label: '회원',
                ),
              if (user.isMaster)
                const BottomNavigationBarItem(
                  icon: Icon(Icons.school),
                  label: '강사',
                ),
              if (user.isMaster)
                const BottomNavigationBarItem(
                  icon: Icon(Icons.class_),
                  label: '수업',
                ),
              if (user.isMaster)
                const BottomNavigationBarItem(
                  icon: Icon(Icons.card_membership),
                  label: '회원권',
                ),
            ],
          ),
        );
      },
    );
  }

  String _getPageTitle(int index) {
    final user = context.read<AuthProvider>().user!;
    
    switch (index) {
      case 0:
        return '대시보드';
      case 1:
        return '스케줄 관리';
      case 2:
        return '예약 관리';
      case 3:
        return '회원 관리';
      case 4:
        if (user.isMaster) return '강사 관리';
        return '필라테스 센터';
      case 5:
        if (user.isMaster) return '수업 타입 관리';
        return '필라테스 센터';
      case 6:
        if (user.isMaster) return '회원권 템플릿 관리';
        return '필라테스 센터';
      default:
        return '필라테스 센터';
    }
  }
}

class _DashboardHome extends StatefulWidget {
  final User user;
  final void Function(int) onNavigate;

  const _DashboardHome({required this.user, required this.onNavigate});

  @override
  State<_DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<_DashboardHome> {
  bool _isResetting = false;

  Future<void> _resetDatabase() async {
    if (_isResetting) return;
    
    // 확인 다이얼로그
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ 데이터베이스 초기화'),
        content: const Text(
          '정말로 데이터베이스를 초기화하시겠습니까?\n\n'
          '⚠️ 모든 사용자, 스케줄, 예약 데이터가 삭제되고\n'
          '새로운 샘플 데이터로 대체됩니다.\n\n'
          '이 작업은 되돌릴 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('초기화 실행'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isResetting = true;
    });

    try {
      // DB 초기화 API 호출
      final apiClient = ApiClient();
      await apiClient.post('/admin/reset-database', {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 데이터베이스가 성공적으로 초기화되었습니다!\n서버가 재시작되면 다시 로그인해주세요.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );

        // 자동 로그아웃 처리
        await context.read<AuthProvider>().logout();
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'DB 초기화에 실패했습니다.';
        
        if (e is ApiException) {
          errorMessage = e.message;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResetting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          context.read<ScheduleProvider>().loadSchedules(date: today),
          context.read<BookingProvider>().loadBookings(),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 환영 메시지
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(
                        Icons.person,
                        size: 30,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '안녕하세요, ${widget.user.name}님!',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '오늘도 좋은 하루 되세요 😊',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 오늘의 스케줄
            Text(
              '오늘의 스케줄',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Consumer<ScheduleProvider>(
              builder: (context, scheduleProvider, _) {
                final todaySchedules = scheduleProvider.getSchedulesByDate(now);
                
                if (scheduleProvider.isLoading) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }

                if (todaySchedules.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Icon(
                            Icons.event_available,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '오늘은 예정된 수업이 없습니다',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: todaySchedules.take(3).map((schedule) {
                    final startTime = DateFormat('HH:mm').format(schedule.dateTime);
                    final endTime = DateFormat('HH:mm').format(schedule.endTime);
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _parseColorString(schedule.classColor ?? 'FF6B6B', Colors.red),
                          child: Text(
                            schedule.classTypeName?.substring(0, 1) ?? 'P',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(schedule.classTypeName ?? '수업'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$startTime - $endTime'),
                            Text('강사: ${schedule.instructorName ?? '미정'}'),
                            Text('예약: ${schedule.currentCapacity}/${schedule.maxCapacity}명'),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            
            const SizedBox(height: 24),

            // 빠른 액션
            Text(
              '빠른 작업',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _QuickActionCard(
                  icon: Icons.schedule,
                  title: '스케줄 보기',
                  subtitle: '수업 일정 확인',
                  onTap: () => widget.onNavigate(1),
                ),
                _QuickActionCard(
                  icon: Icons.book,
                  title: '예약 현황',
                  subtitle: '예약 상태 확인',
                  onTap: () => widget.onNavigate(2),
                ),
                if (widget.user.isMaster || widget.user.isInstructor)
                  _QuickActionCard(
                    icon: Icons.people,
                    title: '회원 관리',
                    subtitle: '회원 정보 관리',
                    onTap: () => widget.onNavigate(3),
                  ),
                if (widget.user.isMaster)
                  _QuickActionCard(
                    icon: Icons.class_,
                    title: '수업 타입 관리',
                    subtitle: '수업 종류 설정',
                    onTap: () => widget.onNavigate(5),
                  ),
                if (widget.user.isMaster)
                  _QuickActionCard(
                    icon: _isResetting ? Icons.hourglass_empty : Icons.refresh,
                    title: _isResetting ? 'DB 초기화 중...' : 'DB 초기화',
                    subtitle: _isResetting ? '진행 중' : '데이터베이스 재설정',
                    onTap: () => _resetDatabase(),
                  ),
                if (widget.user.isMaster)
                  _QuickActionCard(
                    icon: Icons.settings,
                    title: '설정',
                    subtitle: '시스템 설정',
                    onTap: () {
                      // 설정 화면으로 이동
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}