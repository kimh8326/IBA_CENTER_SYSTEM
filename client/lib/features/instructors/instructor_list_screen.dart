import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/instructor_provider.dart';
import '../../core/models/user.dart';
import 'instructor_detail_screen.dart';
import 'instructor_create_screen.dart';

class InstructorListScreen extends StatefulWidget {
  const InstructorListScreen({super.key});

  @override
  State<InstructorListScreen> createState() => _InstructorListScreenState();
}

class _InstructorListScreenState extends State<InstructorListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'active';
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InstructorProvider>().loadInstructors(status: _selectedStatus);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final query = _searchController.text.trim();
    context.read<InstructorProvider>().loadInstructors(
      status: _selectedStatus,
      search: query.isEmpty ? null : query,
    );
  }

  void _onStatusChanged(String status) {
    setState(() {
      _selectedStatus = status;
    });
    _onSearch();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Column(
        children: [
          // 검색 및 필터 바
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Column(
              children: [
                // 검색창
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '강사 이름, 전화번호, 이메일로 검색',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearch();
                      },
                    ),
                  ),
                  onSubmitted: (_) => _onSearch(),
                ),
                const SizedBox(height: 12),
                // 상태 필터
                Row(
                  children: [
                    Text(
                      '상태:',
                      style: theme.textTheme.labelMedium,
                    ),
                    const SizedBox(width: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'active',
                          label: Text('활성'),
                          icon: Icon(Icons.check_circle),
                        ),
                        ButtonSegment(
                          value: 'inactive',
                          label: Text('비활성'),
                          icon: Icon(Icons.block),
                        ),
                        ButtonSegment(
                          value: 'all',
                          label: Text('전체'),
                          icon: Icon(Icons.list),
                        ),
                      ],
                      selected: {_selectedStatus},
                      onSelectionChanged: (Set<String> selection) {
                        _onStatusChanged(selection.first);
                      },
                      showSelectedIcon: false,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // 강사 목록
          Expanded(
            child: Consumer<InstructorProvider>(
              builder: (context, instructorProvider, _) {
                if (instructorProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (instructorProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '강사 목록을 불러올 수 없습니다',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          instructorProvider.error!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => context.read<InstructorProvider>()
                              .loadInstructors(status: _selectedStatus),
                          child: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  );
                }

                final instructors = instructorProvider.instructors;

                if (instructors.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '강사가 없습니다',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '새 강사를 추가해보세요',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => context.read<InstructorProvider>()
                      .loadInstructors(status: _selectedStatus),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: instructors.length,
                    itemBuilder: (context, index) {
                      final instructor = instructors[index];
                      return _InstructorCard(
                        instructor: instructor,
                        onTap: () => _navigateToInstructorDetail(instructor),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateInstructor,
        icon: const Icon(Icons.add),
        label: const Text('강사 추가'),
      ),
    );
  }

  void _navigateToInstructorDetail(User instructor) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => InstructorDetailScreen(instructor: instructor),
      ),
    );
  }

  void _navigateToCreateInstructor() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const InstructorCreateScreen(),
      ),
    ).then((_) {
      // 강사 생성 후 목록 새로고침
      context.read<InstructorProvider>().loadInstructors(status: _selectedStatus);
    });
  }
}

class _InstructorCard extends StatelessWidget {
  final User instructor;
  final VoidCallback onTap;

  const _InstructorCard({
    required this.instructor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy.MM.dd');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      instructor.name.isNotEmpty ? instructor.name[0] : 'I',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              instructor.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: instructor.isActive
                                    ? theme.colorScheme.primaryContainer
                                    : theme.colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                instructor.isActive ? '활성' : '비활성',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: instructor.isActive
                                      ? theme.colorScheme.onPrimaryContainer
                                      : theme.colorScheme.onErrorContainer,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              instructor.phone,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (instructor.email != null && instructor.email!.isNotEmpty) ...[
                              const SizedBox(width: 16),
                              Icon(
                                Icons.email,
                                size: 16,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  instructor.email!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              
              if (instructor.specializations != null && instructor.specializations!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.fitness_center,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          instructor.specializations!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 12),
              Row(
                children: [
                  if (instructor.experienceYears != null) ...[
                    Icon(
                      Icons.school,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '경력 ${instructor.experienceYears}년',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    '가입일: ${dateFormat.format(instructor.createdAtDateTime)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}