import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/notification_provider.dart';

class AdminMessageScreen extends StatefulWidget {
  const AdminMessageScreen({super.key});

  @override
  State<AdminMessageScreen> createState() => _AdminMessageScreenState();
}

class _AdminMessageScreenState extends State<AdminMessageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedTarget = 'all_members';
  bool _isSending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSending = true;
    });

    final provider = context.read<NotificationProvider>();
    final success = await provider.sendAdminMessage(
      target: _selectedTarget,
      title: _titleController.text.trim(),
      message: _messageController.text.trim(),
    );

    setState(() {
      _isSending = false;
    });

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('알림이 성공적으로 발송되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
        _titleController.clear();
        _messageController.clear();
        setState(() {
          _selectedTarget = 'all_members';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('알림 발송 실패: ${provider.error ?? "알 수 없는 오류"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('관리자 메시지 발송'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 안내 카드
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '모든 회원 또는 모든 강사에게 알림을 발송할 수 있습니다.',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 발송 대상 선택
              Text(
                '발송 대상',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'all_members',
                    label: Text('모든 회원'),
                    icon: Icon(Icons.people),
                  ),
                  ButtonSegment(
                    value: 'all_instructors',
                    label: Text('모든 강사'),
                    icon: Icon(Icons.fitness_center),
                  ),
                ],
                selected: {_selectedTarget},
                onSelectionChanged: (Set<String> selected) {
                  setState(() {
                    _selectedTarget = selected.first;
                  });
                },
              ),
              const SizedBox(height: 24),

              // 제목 입력
              Text(
                '제목',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: '알림 제목을 입력하세요',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '제목을 입력해주세요';
                  }
                  return null;
                },
                maxLength: 100,
              ),
              const SizedBox(height: 24),

              // 메시지 입력
              Text(
                '메시지',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: '알림 내용을 입력하세요',
                  prefixIcon: Icon(Icons.message),
                  alignLabelWithHint: true,
                ),
                maxLines: 6,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '메시지를 입력해주세요';
                  }
                  return null;
                },
                maxLength: 500,
              ),
              const SizedBox(height: 32),

              // 발송 버튼
              FilledButton.icon(
                onPressed: _isSending ? null : _sendMessage,
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(_isSending ? '발송 중...' : '알림 발송'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),

              const SizedBox(height: 16),

              // 취소 버튼
              OutlinedButton.icon(
                onPressed: _isSending
                    ? null
                    : () {
                        Navigator.pop(context);
                      },
                icon: const Icon(Icons.close),
                label: const Text('취소'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
