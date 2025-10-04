import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/instructor_provider.dart';
import '../../core/api/api_client.dart';
import '../../core/models/class_type.dart';

class InstructorCreateScreen extends StatefulWidget {
  const InstructorCreateScreen({super.key});

  @override
  State<InstructorCreateScreen> createState() => _InstructorCreateScreenState();
}

class _InstructorCreateScreenState extends State<InstructorCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _specializationsController = TextEditingController();
  final _certificationsController = TextEditingController();
  final _experienceYearsController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _bioController = TextEditingController();

  final ApiClient _apiClient = ApiClient();
  List<ClassType> _classTypes = [];
  Set<int> _selectedClassTypeIds = {};
  bool _isLoading = false;
  bool _isLoadingClassTypes = true;

  @override
  void initState() {
    super.initState();
    _loadClassTypes();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _specializationsController.dispose();
    _certificationsController.dispose();
    _experienceYearsController.dispose();
    _hourlyRateController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadClassTypes() async {
    try {
      final response = await _apiClient.get('/class-types');
      final List<dynamic> data = response['classTypes'];

      setState(() {
        _classTypes = data
            .map((json) => ClassType.fromJson(json as Map<String, dynamic>))
            .where((classType) => classType.isActive)
            .toList();
        _isLoadingClassTypes = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingClassTypes = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('수업 타입 로드 실패: $e')),
        );
      }
    }
  }

  Future<void> _createInstructor() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 일치하지 않습니다.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    if (_selectedClassTypeIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최소 하나 이상의 수업 타입을 선택해주세요')),
      );
      return;
    }

    try {
      final success = await context.read<InstructorProvider>().createInstructor(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        specializations: _specializationsController.text.trim().isEmpty ? null : _specializationsController.text.trim(),
        experienceYears: _experienceYearsController.text.trim().isEmpty ? null : int.tryParse(_experienceYearsController.text.trim()),
        certifications: _certificationsController.text.trim().isEmpty ? null : _certificationsController.text.trim(),
        hourlyRate: _hourlyRateController.text.trim().isEmpty ? null : double.tryParse(_hourlyRateController.text.trim()),
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        classTypeIds: _selectedClassTypeIds.toList(),
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('강사가 생성되었습니다.')),
          );
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          final error = context.read<InstructorProvider>().error ?? '강사 생성에 실패했습니다.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('강사 추가'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createInstructor,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('저장'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 기본 정보
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '기본 정보',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: '이름',
                          hintText: '한글 또는 영문으로 입력하세요',
                        ),
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '이름을 입력해주세요';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: '전화번호',
                          hintText: '전화번호를 입력하세요',
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '전화번호를 입력해주세요';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: '이메일',
                          hintText: '이메일을 입력하세요 (선택사항)',
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),

              // 비밀번호
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '비밀번호',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: '비밀번호',
                          hintText: '비밀번호를 입력하세요',
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '비밀번호를 입력해주세요';
                          }
                          if (value.length < 6) {
                            return '비밀번호는 6자 이상이어야 합니다';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: const InputDecoration(
                          labelText: '비밀번호 확인',
                          hintText: '비밀번호를 다시 입력하세요',
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '비밀번호 확인을 입력해주세요';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 수업 타입 선택
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '담당 수업 타입 *',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '이 강사가 담당할 수 있는 수업 타입을 선택하세요',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_isLoadingClassTypes)
                        const Center(child: CircularProgressIndicator())
                      else if (_classTypes.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning_amber, color: Colors.orange),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '등록된 수업 타입이 없습니다. 먼저 수업 타입을 생성해주세요.',
                                  style: TextStyle(color: Colors.orange),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _classTypes.map((classType) {
                            final isSelected = _selectedClassTypeIds.contains(classType.id);
                            return FilterChip(
                              label: Text(classType.name),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedClassTypeIds.add(classType.id);
                                  } else {
                                    _selectedClassTypeIds.remove(classType.id);
                                  }
                                });
                              },
                              selectedColor: Theme.of(context).colorScheme.primaryContainer,
                              checkmarkColor: Theme.of(context).colorScheme.primary,
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 전문 정보
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '전문 정보',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _specializationsController,
                        decoration: const InputDecoration(
                          labelText: '전문 분야',
                          hintText: '예) 필라테스, 요가, 재활운동 등',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _experienceYearsController,
                        decoration: const InputDecoration(
                          labelText: '경력 (년)',
                          hintText: '경력 년수를 입력하세요',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _certificationsController,
                        decoration: const InputDecoration(
                          labelText: '자격증',
                          hintText: '보유 자격증을 입력하세요',
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _hourlyRateController,
                        decoration: const InputDecoration(
                          labelText: '시간당 수업료',
                          hintText: '시간당 수업료를 입력하세요',
                          suffixText: '원',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _bioController,
                        decoration: const InputDecoration(
                          labelText: '소개',
                          hintText: '강사 소개를 입력하세요',
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}