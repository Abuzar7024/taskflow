import 'package:equatable/equatable.dart';

/// Failures a reviewer can force from Profile → Developer Tools.
enum SimulatedFailure {
  none('Off', 'Requests behave normally'),
  timeout('Network timeout', 'Requests time out after a short delay'),
  serverError('Server error (500)', 'Reads and writes fail with a server error'),
  notFound('Not found (404)', 'Loading a single task or project fails'),
  validationError(
    'Validation error',
    'The server rejects create and update requests',
  ),
  unauthorized(
    'Unauthorized (401)',
    'The next request forces a token refresh, then signs you out',
  );

  const SimulatedFailure(this.label, this.description);

  final String label;
  final String description;
}

class DevSettings extends Equatable {
  const DevSettings({
    this.failure = SimulatedFailure.none,
    this.offline = false,
    this.slowNetwork = false,
  });

  factory DevSettings.fromJson(Map<String, dynamic> json) {
    return DevSettings(
      failure: SimulatedFailure.values.firstWhere(
        (f) => f.name == json['failure'],
        orElse: () => SimulatedFailure.none,
      ),
      offline: json['offline'] as bool? ?? false,
      slowNetwork: json['slow_network'] as bool? ?? false,
    );
  }

  final SimulatedFailure failure;
  final bool offline;
  final bool slowNetwork;

  bool get isDefault =>
      failure == SimulatedFailure.none && !offline && !slowNetwork;

  DevSettings copyWith({
    SimulatedFailure? failure,
    bool? offline,
    bool? slowNetwork,
  }) {
    return DevSettings(
      failure: failure ?? this.failure,
      offline: offline ?? this.offline,
      slowNetwork: slowNetwork ?? this.slowNetwork,
    );
  }

  Map<String, dynamic> toJson() => {
    'failure': failure.name,
    'offline': offline,
    'slow_network': slowNetwork,
  };

  @override
  List<Object?> get props => [failure, offline, slowNetwork];
}
