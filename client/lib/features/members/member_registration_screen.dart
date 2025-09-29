import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/api/api_client.dart';
import '../../core/models/membership_template.dart';

class MemberRegistrationScreen extends StatefulWidget {
  const MemberRegistrationScreen({super.key});

  @override
  State<MemberRegistrationScreen> createState() => _MemberRegistrationScreenState();
}

class _MemberRegistrationScreenState extends State<MemberRegistrationScreen>
    with TickerProviderStateMixin {
  final ApiClient _apiClient = ApiClient();
  late TabController _tabController;
  
  // 기본 정보
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _medicalNotesController = TextEditingController();
  
  String? _selectedGender;
  DateTime? _selectedBirthDate;
  
  // 회원권 정보
  List<MembershipTemplate> _membershipTemplates = [];
  MembershipTemplate? _selectedTemplate;
  final _purchasePriceController = TextEditingController();
  DateTime? _startDate;
  String _paymentMethod = 'card';
  
  bool _isLoading = false;
  bool _isSubmitting = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _startDate = DateTime.now();
    _loadMembershipTemplates();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _birthDateController.dispose();
    _emergencyContactController.dispose();
    _medicalNotesController.dispose();
    _purchasePriceController.dispose();
    super.dispose();
  }
  
  Future<void> _loadMembershipTemplates() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final response = await _apiClient.get('/membership-templates');
      final List<dynamic> data = response['membershipTemplates'];
      
      _membershipTemplates = data
          .map((json) => MembershipTemplate.fromJson(json as Map<String, dynamic>))
          .where((template) => template.isActive)
          .toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('회원권 템플릿 로드 실패: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('ko', 'KR'),
    );
    
    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
        _birthDateController.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }
  
  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ko', 'KR'),
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }
  
  void _onTemplateSelected(MembershipTemplate? template) {
    setState(() {
      _selectedTemplate = template;
      if (template != null) {
        _purchasePriceController.text = template.price.toString();
      } else {
        _purchasePriceController.clear();
      }
    });
  }
  
  bool _validateBasicInfo() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름을 입력해주세요')),
      );
      return false;
    }
    
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('전화번호를 입력해주세요')),
      );
      return false;
    }
    
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호를 입력해주세요')),
      );
      return false;
    }
    
    if (_passwordController.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호는 최소 4자 이상이어야 합니다')),
      );
      return false;
    }
    
    return true;
  }
  
  bool _validateMembershipInfo() {
    if (_selectedTemplate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원권을 선택해주세요')),
      );
      return false;
    }
    
    if (_purchasePriceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('구매 가격을 입력해주세요')),
      );
      return false;
    }
    
    return true;
  }
  
  Future<void> _registerMember() async {
    if (!_validateBasicInfo() || !_validateMembershipInfo()) {
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      // 회원 등록 데이터 준비
      final memberData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        'password': _passwordController.text,
        'birthDate': _selectedBirthDate?.toIso8601String().split('T')[0],
        'gender': _selectedGender,
        'emergencyContact': _emergencyContactController.text.trim().isEmpty ? null : _emergencyContactController.text.trim(),
        'medicalNotes': _medicalNotesController.text.trim().isEmpty ? null : _medicalNotesController.text.trim(),
        'membershipTemplate': {
          'templateId': _selectedTemplate!.id,
          'startDate': _startDate!.toIso8601String().split('T')[0],
          'purchasePrice': double.parse(_purchasePriceController.text.trim()),
          'paymentMethod': _paymentMethod,
        },
      };
      
      final response = await _apiClient.post('/users/register-member', memberData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? '회원이 성공적으로 등록되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context, true); // 등록 성공 표시
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('회원 등록 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원 등록'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '기본 정보', icon: Icon(Icons.person)),
            Tab(text: '회원권 선택', icon: Icon(Icons.card_membership)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBasicInfoTab(),
          _buildMembershipTab(),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: Row(
          children: [
            if (_tabController.index > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _tabController.animateTo(_tabController.index - 1);
                  },
                  child: const Text('이전'),
                ),
              ),
            if (_tabController.index > 0) const SizedBox(width: 16),
            Expanded(
              child: FilledButton(
                onPressed: _isSubmitting ? null : () {
                  if (_tabController.index == 0) {
                    if (_validateBasicInfo()) {
                      _tabController.animateTo(1);
                    }
                  } else {
                    _registerMember();
                  }
                },
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_tabController.index == 0 ? '다음' : '등록 완료'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '필수 정보',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: '이름 *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                      hintText: '한글 또는 영문',
                    ),
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: '전화번호 *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: '이메일 (선택사항)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: '초기 비밀번호 *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                      helperText: '회원이 로그인할 때 사용할 비밀번호',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '추가 정보 (선택사항)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _birthDateController,
                    readOnly: true,
                    onTap: _selectBirthDate,
                    decoration: const InputDecoration(
                      labelText: '생년월일',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    decoration: const InputDecoration(
                      labelText: '성별',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.wc),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('남성')),
                      DropdownMenuItem(value: 'female', child: Text('여성')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emergencyContactController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: '비상 연락처',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.emergency),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _medicalNotesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: '건강상 주의사항',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.medical_services),
                      helperText: '알레르기, 질병, 부상 등',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMembershipTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '회원권 선택',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_membershipTemplates.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text('등록된 회원권 템플릿이 없습니다. 관리자에게 문의하세요.'),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: _membershipTemplates.map((template) {
                        final isSelected = _selectedTemplate?.id == template.id;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                          child: InkWell(
                            onTap: () => _onTemplateSelected(template),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Radio<int>(
                                    value: template.id,
                                    groupValue: _selectedTemplate?.id,
                                    onChanged: (value) {
                                      if (value != null) {
                                        final selected = _membershipTemplates
                                            .firstWhere((t) => t.id == value);
                                        _onTemplateSelected(selected);
                                      }
                                    },
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          template.name,
                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text('${template.sessionsText} • '),
                                            Text('${template.validityText} • '),
                                            Text(
                                              template.priceText,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (template.classTypeName != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            '수업: ${template.classTypeName}',
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
          
          if (_selectedTemplate != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '결제 정보',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _purchasePriceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: '실제 구매 가격 *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                        suffix: Text('원'),
                        helperText: '할인이나 프로모션이 있는 경우 실제 결제 금액 입력',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, 
                            color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Text('시작일: ', 
                            style: Theme.of(context).textTheme.titleSmall),
                        Text(
                          _startDate != null 
                              ? '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}'
                              : '선택 안됨',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _selectStartDate,
                          child: const Text('변경'),
                        ),
                      ],
                    ),
                    const Divider(),
                    Text('결제 방법', 
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('카드'),
                            value: 'card',
                            groupValue: _paymentMethod,
                            onChanged: (value) {
                              setState(() {
                                _paymentMethod = value!;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('현금'),
                            value: 'cash',
                            groupValue: _paymentMethod,
                            onChanged: (value) {
                              setState(() {
                                _paymentMethod = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    RadioListTile<String>(
                      title: const Text('계좌이체'),
                      value: 'transfer',
                      groupValue: _paymentMethod,
                      onChanged: (value) {
                        setState(() {
                          _paymentMethod = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}