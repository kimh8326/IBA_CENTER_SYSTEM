import 'package:flutter/material.dart';
import '../../core/models/user.dart';

class InstructorDetailScreen extends StatelessWidget {
  final User instructor;

  const InstructorDetailScreen({
    super.key,
    required this.instructor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(instructor.name),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '강사 상세 화면',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(
              instructor.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              instructor.phone,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (instructor.email != null) ...[
              const SizedBox(height: 8),
              Text(
                instructor.email!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ],
        ),
      ),
    );
  }
}