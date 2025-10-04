import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_client.dart';
import '../../core/models/user.dart';
import '../../core/models/membership.dart';
import '../../core/models/booking.dart';
import '../../core/providers/auth_provider.dart';

class UserDetailScreen extends StatefulWidget {
  final int userId;

  const UserDetailScreen({
    super.key,
    required this.userId,
  });

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final ApiClient _apiClient = ApiClient();
  
  User? _user;
  List<Membership> _memberships = [];
  List<Booking> _bookings = [];
  
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _error;

  // 편집용 컨트롤러들
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _medicalNotesController = TextEditingController();
  
  String? _selectedGender;
  DateTime? _selectedBirthDate;

  @override
  void initState() {
    super.initState();
    _loadUserDetail();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _emergencyContactController.dispose();
    _medicalNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadUserDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiClient.get('/users/${widget.userId}');
      
      _user = User.fromJson(response['user']);
      
      // 프로필 정보가 있으면 폼 컨트롤러에 설정
      if (response['profile'] != null) {
        final profile = response['profile'];
        _selectedGender = profile['gender'];
        if (profile['birth_date'] != null) {
          _selectedBirthDate = DateTime.parse(profile['birth_date']);
        }
        _emergencyContactController.text = profile['emergency_contact'] ?? '';
        _medicalNotesController.text = profile['medical_notes'] ?? '';
      }

      // 회원권 정보 로드
      if (response['memberships'] != null) {
        final List<dynamic> membershipData = response['memberships'];
        _memberships = membershipData
            .map((json) => Membership.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        _memberships = [];
      }

      // TODO: 예약 정보 로드
      // _bookings = ...
      
      // 편집용 컨트롤러에 기본값 설정
      _nameController.text = _user!.name;
      _phoneController.text = _user!.phone;
      _emailController.text = _user!.email ?? '';

    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveUserInfo() async {
    if (_user == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final updateData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        'profile': {
          'birth_date': _selectedBirthDate?.toIso8601String().split('T')[0],
          'gender': _selectedGender,
          'emergency_contact': _emergencyContactController.text.trim().isEmpty ? null : _emergencyContactController.text.trim(),
          'medical_notes': _medicalNotesController.text.trim().isEmpty ? null : _medicalNotesController.text.trim(),
        }
      };

      await _apiClient.put('/users/${widget.userId}', updateData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('회원 정보가 수정되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
        
        setState(() {
          _isEditing = false;
        });
        
        // 데이터 새로고침
        _loadUserDetail();
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('수정 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteUser() async {
    if (_user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('회원 삭제'),
        content: Text('정말로 ${_user!.name}님을 삭제하시겠습니까?\n\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _apiClient.delete('/users/${widget.userId}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('회원이 삭제되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
        
        // 목록 화면으로 돌아가면서 새로고침 신호 전달
        Navigator.pop(context, true);
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('삭제 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      
      if (!_isEditing && _user != null) {
        // 편집 취소 시 원래 값으로 복원
        _nameController.text = _user!.name;
        _phoneController.text = _user!.phone;
        _emailController.text = _user!.email ?? '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final isMaster = authProvider.user?.userType == 'master';

    return Scaffold(
      appBar: AppBar(
        title: Text(_user?.name ?? '회원 상세'),
        actions: [
          if (_isEditing) ...[
            IconButton(
              onPressed: _isSaving ? null : _toggleEditMode,
              icon: const Icon(Icons.close),
              tooltip: '취소',
            ),
            IconButton(
              onPressed: _isSaving ? null : _saveUserInfo,
              icon: _isSaving 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
              tooltip: '저장',
            ),
          ] else ...[
            IconButton(
              onPressed: _toggleEditMode,
              icon: const Icon(Icons.edit),
              tooltip: '수정',
            ),
            if (isMaster)
              PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('삭제', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'delete') {
                    _deleteUser();
                  }
                },
              ),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              '데이터를 불러올 수 없습니다',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(_error!),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadUserDetail,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_user == null) {
      return const Center(child: Text('사용자를 찾을 수 없습니다'));
    }

    return RefreshIndicator(
      onRefresh: _loadUserDetail,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserInfoCard(),
            const SizedBox(height: 16),
            _buildMembershipsCard(),
            const SizedBox(height: 16),
            _buildBookingsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '기본 정보',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // 이름
            _isEditing
              ? TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '이름 *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                )
              : _buildInfoRow('이름', _user!.name, Icons.person),
            
            const SizedBox(height: 16),
            
            // 전화번호
            _isEditing
              ? TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: '전화번호 *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                )
              : _buildInfoRow('전화번호', _user!.phone, Icons.phone),
            
            const SizedBox(height: 16),
            
            // 이메일
            _isEditing
              ? TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: '이메일',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                )
              : _buildInfoRow('이메일', _user!.email ?? '미입력', Icons.email),
            
            const SizedBox(height: 16),
            
            // 가입일
            _buildInfoRow(
              '가입일', 
              DateFormat('yyyy-MM-dd').format(_user!.createdAtDateTime),
              Icons.calendar_today,
            ),
            
            const SizedBox(height: 16),
            
            // 상태
            Row(
              children: [
                const Icon(Icons.info_outline, size: 20),
                const SizedBox(width: 12),
                Text(
                  '상태',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _user!.isActive ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _user!.isActive ? '활성' : '비활성',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembershipsCard() {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '회원권 정보',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            if (_memberships.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 8),
                    Expanded(child: Text('보유 중인 회원권이 없습니다')),
                  ],
                ),
              )
            else
              Column(
                children: _memberships.map((membership) => _buildMembershipCard(membership)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsCard() {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '수업 이력',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            if (_bookings.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 8),
                    Expanded(child: Text('수업 이력이 없습니다')),
                  ],
                ),
              )
            else
              // TODO: 예약 이력 목록 표시
              const Text('예약 이력 표시 예정'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMembershipCard(Membership membership) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    membership.templateName ?? '회원권',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: membership.isActive ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    membership.statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '잔여 횟수',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${membership.remainingSessions}회',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: membership.remainingSessions > 0 
                            ? theme.colorScheme.primary 
                            : theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '구매 가격',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${NumberFormat('#,###').format(membership.purchasePrice)}원',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  '기간: ${membership.startDate} ~ ${membership.endDate}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            
            if (membership.remainingDays > 0) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '남은 기간: ${membership.remainingDays}일',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: membership.remainingDays < 7 
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
            
            if (membership.totalSessions != null) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: membership.usageProgress,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  membership.usageProgress > 0.8 
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '사용률: ${(membership.usageProgress * 100).toInt()}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${membership.totalSessions! - membership.remainingSessions}/${membership.totalSessions}회 사용',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}