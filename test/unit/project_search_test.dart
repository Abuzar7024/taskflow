import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/domain/entities/entities.dart';
import 'package:taskflow/domain/entities/enums.dart';
import 'package:taskflow/presentation/projects/project_providers.dart';

Project project(String name, {String description = '', int tasks = 0, int day = 1}) {
  return Project(
    id: name,
    orgId: 'org',
    name: name,
    description: description,
    status: ProjectStatus.active,
    createdAt: DateTime(2026, 1, day),
    taskCount: tasks,
  );
}

void main() {
  final items = [
    project('Website Relaunch', description: 'Marketing site', tasks: 6, day: 1),
    project('Mobile App v2', description: 'Customer app', tasks: 5, day: 3),
    project('Analytics', description: 'Dashboards', tasks: 9, day: 2),
  ];

  group('search', () {
    test('an empty query returns everything', () {
      expect(
        searchAndSortProjects(items, '', ProjectSort.recent).length,
        items.length,
      );
    });

    test('matches on name, case-insensitively', () {
      final result = searchAndSortProjects(items, 'mobile', ProjectSort.recent);
      expect(result.single.name, 'Mobile App v2');
    });

    test('matches on description', () {
      final result = searchAndSortProjects(items, 'dashboards', ProjectSort.recent);
      expect(result.single.name, 'Analytics');
    });

    test('ignores surrounding whitespace', () {
      expect(
        searchAndSortProjects(items, '  analytics  ', ProjectSort.recent).length,
        1,
      );
    });

    test('a query matching nothing returns empty', () {
      expect(searchAndSortProjects(items, 'zzzz', ProjectSort.recent), isEmpty);
    });
  });

  group('sort', () {
    test('recent puts the newest first', () {
      final result = searchAndSortProjects(items, '', ProjectSort.recent);
      expect(result.first.name, 'Mobile App v2');
    });

    test('name sorts alphabetically', () {
      final result = searchAndSortProjects(items, '', ProjectSort.nameAsc);
      expect(result.map((p) => p.name).toList(),
          ['Analytics', 'Mobile App v2', 'Website Relaunch']);
    });

    test('most tasks sorts by task count', () {
      final result = searchAndSortProjects(items, '', ProjectSort.mostTasks);
      expect(result.first.taskCount, 9);
    });

    test('does not mutate the source list', () {
      final before = items.map((p) => p.name).toList();
      searchAndSortProjects(items, '', ProjectSort.nameAsc);
      expect(items.map((p) => p.name).toList(), before);
    });
  });
}
