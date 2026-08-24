import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/core/utils/formatters.dart';
import 'package:taskflow/core/utils/validators.dart';

void main() {
  group('email', () {
    test('accepts ordinary addresses', () {
      expect(Validators.email('ava.admin@nimbusdigital.test'), isNull);
      expect(Validators.email('a+tag@example.co.uk'), isNull);
    });

    test('rejects empty input', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email(null), isNotNull);
    });

    test('rejects malformed addresses', () {
      for (final invalid in ['no-at-sign', 'missing@domain', '@example.com']) {
        expect(Validators.email(invalid), isNotNull, reason: invalid);
      }
    });

    test('ignores surrounding whitespace', () {
      expect(Validators.email('  ava.admin@nimbusdigital.test  '), isNull);
    });
  });

  group('password', () {
    test('requires the minimum length on registration', () {
      expect(Validators.password('short'), isNotNull);
      expect(Validators.password('Password123!'), isNull);
    });

    test('login only requires a non-empty value', () {
      expect(Validators.loginPassword('x'), isNull);
      expect(Validators.loginPassword(''), isNotNull);
    });

    test('confirmation must match', () {
      expect(Validators.confirmPassword('abc', 'abc'), isNull);
      expect(Validators.confirmPassword('abc', 'abd'), isNotNull);
      expect(Validators.confirmPassword('', 'abc'), isNotNull);
    });
  });

  group('names and titles', () {
    test('full name rejects empty and overlong values', () {
      expect(Validators.fullName(''), isNotNull);
      expect(Validators.fullName('A'), isNotNull);
      expect(Validators.fullName('Ava Thompson'), isNull);
      expect(Validators.fullName('x' * 61), isNotNull);
    });

    test('task title enforces its bounds', () {
      expect(Validators.taskTitle(''), isNotNull);
      expect(Validators.taskTitle('ab'), isNotNull);
      expect(Validators.taskTitle('Fix the contact form'), isNull);
      expect(
        Validators.taskTitle('x' * (Validators.taskTitleMaxLength + 1)),
        isNotNull,
      );
    });

    test('a whitespace-only title is rejected', () {
      expect(Validators.taskTitle('    '), isNotNull);
    });

    test('project name enforces its bounds', () {
      expect(Validators.projectName(''), isNotNull);
      expect(Validators.projectName('Website Relaunch'), isNull);
      expect(
        Validators.projectName('x' * (Validators.projectNameMaxLength + 1)),
        isNotNull,
      );
    });
  });

  group('description', () {
    test('is optional', () {
      expect(Validators.description(''), isNull);
      expect(Validators.description(null), isNull);
    });

    test('enforces a ceiling', () {
      expect(
        Validators.description('x' * Validators.descriptionMaxLength),
        isNull,
      );
      expect(
        Validators.description('x' * (Validators.descriptionMaxLength + 1)),
        isNotNull,
      );
    });
  });

  group('date formatting', () {
    final now = DateTime(2026, 2, 10);

    test('relativeDay names nearby days', () {
      expect(Dates.relativeDay(DateTime(2026, 2, 10), now), 'Today');
      expect(Dates.relativeDay(DateTime(2026, 2, 11), now), 'Tomorrow');
      expect(Dates.relativeDay(DateTime(2026, 2, 9), now), 'Yesterday');
    });

    test('relativeDay reports overdue days', () {
      expect(Dates.relativeDay(DateTime(2026, 2, 5), now), '5 days overdue');
    });

    test('relativeDay reports the coming week', () {
      expect(Dates.relativeDay(DateTime(2026, 2, 13), now), 'In 3 days');
    });

    test('relativeDay falls back to a date further out', () {
      expect(Dates.relativeDay(DateTime(2026, 4, 1), now), '1 Apr');
    });

    test('short() includes the year only when it differs', () {
      expect(Dates.short(DateTime(2026, 3, 5), now: now), '5 Mar');
      expect(Dates.short(DateTime(2025, 3, 5), now: now), '5 Mar 2025');
    });

    test('timeAgo describes the recent past', () {
      expect(Dates.timeAgo(now.subtract(const Duration(seconds: 5)), now),
          'Just now');
      expect(Dates.timeAgo(now.subtract(const Duration(minutes: 5)), now),
          '5m ago');
      expect(
          Dates.timeAgo(now.subtract(const Duration(hours: 3)), now), '3h ago');
      expect(
          Dates.timeAgo(now.subtract(const Duration(days: 2)), now), '2d ago');
      expect(
          Dates.timeAgo(now.subtract(const Duration(days: 14)), now), '2w ago');
    });

    test('timeAgo treats a future timestamp as just now', () {
      expect(Dates.timeAgo(now.add(const Duration(hours: 1)), now), 'Just now');
    });

    test('toWireDate matches the mock data format', () {
      expect(Dates.toWireDate(DateTime(2026, 1, 5)), '2026-01-05');
      expect(Dates.toWireDate(DateTime(2026, 12, 31)), '2026-12-31');
    });
  });

  group('plurals', () {
    test('switches on count', () {
      expect(Plurals.count(1, 'task'), '1 task');
      expect(Plurals.count(2, 'task'), '2 tasks');
    });

    test('countLabel words zero', () {
      expect(Plurals.countLabel(0), 'No tasks');
      expect(Plurals.countLabel(1), '1 task');
      expect(Plurals.countLabel(6), '6 tasks');
    });
  });
}
