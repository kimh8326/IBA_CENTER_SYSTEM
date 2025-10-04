import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/api/api_client.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serverUrlController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _showServerUrl = false;

  @override
  void initState() {
    super.initState();
    _loadServerUrl();
  }

  Future<void> _loadServerUrl() async {
    final savedUrl = await ApiClient.getServerUrl();
    if (savedUrl != null) {
      _serverUrlController.text = savedUrl;
    } else {
      // 기본값 설정
      _serverUrlController.text = 'http://192.168.0.20:3000';
      _showServerUrl = true; // 저장된 URL이 없으면 필드 표시
      setState(() {});
    }
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 서버 URL 저장
      await ApiClient.setServerUrl(_serverUrlController.text.trim());

      await context.read<AuthProvider>().login(
        _phoneController.text.trim(),
        _passwordController.text,
      );
    } catch (e) {
      if (mounted) {
        String errorMessage = '로그인에 실패했습니다.';
        
        if (e is ApiException) {
          errorMessage = e.message;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
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
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 로고 및 제목
                  Icon(
                    Icons.fitness_center,
                    size: 80,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '필라테스 센터',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    '관리 시스템',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // 서버 URL 입력 (설정 아이콘 클릭 시 표시/숨김)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _showServerUrl ? '서버 설정' : '서버: ${_serverUrlController.text}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _showServerUrl ? Icons.expand_less : Icons.settings,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _showServerUrl = !_showServerUrl;
                          });
                        },
                      ),
                    ],
                  ),
                  if (_showServerUrl) ...[
                    TextFormField(
                      controller: _serverUrlController,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: '서버 URL',
                        hintText: 'http://192.168.0.20:3000',
                        prefixIcon: Icon(Icons.dns),
                        helperText: '예: http://192.168.0.20:3000',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '서버 URL을 입력해주세요';
                        }
                        if (!value.startsWith('http://') && !value.startsWith('https://')) {
                          return 'http:// 또는 https://로 시작해야 합니다';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 전화번호 입력
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: '전화번호',
                      hintText: '전화번호를 입력하세요',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '전화번호를 입력해주세요';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // 비밀번호 입력
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: '비밀번호',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '비밀번호를 입력해주세요';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _login(),
                  ),
                  const SizedBox(height: 32),

                  // 로그인 버튼
                  FilledButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('로그인'),
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