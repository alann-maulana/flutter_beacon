//  Copyright (c) 2018 Eyro Labs.
//  Licensed under Apache License v2.0 that can be
//  found in the LICENSE file.

part of flutter_beacon;

/// Enum for defining monitoring event type.
enum MonitoringEventType {
  didEnterRegion,
  didExitRegion,
  didDetermineStateForRegion
}

/// Enum for defining monitoring state
enum MonitoringState { inside, outside, unknown }

/// Class for managing monitoring result from scanning iBeacon process.
class MonitoringResult {
  /// The [MonitoringEventType] of monitoring result
  final MonitoringEventType monitoringEventType;

  /// The [MonitoringState] of monitoring result
  ///
  /// This value is not null when [monitoringEventType] is [MonitoringEventType.didDetermineStateForRegion]
  final MonitoringState? monitoringState;

  /// The [Region] of ranging result.
  final Region region;

  /// Constructor for deserialize dynamic json into [MonitoringResult].
  MonitoringResult.from(dynamic json)
      : this.monitoringEventType = _parseMonitoringEventType(json['event']),
        this.monitoringState = _parseMonitoringState(json['state']),
        this.region = Region.fromJson(json['region']);

  /// Parsing dynamic state into [MonitoringState].
  static MonitoringState? _parseMonitoringState(dynamic state) {
    if (!(state is String)) {
      return null;
    }

    if (state.toLowerCase() == 'inside') {
      return MonitoringState.inside;
    } else if (state.toLowerCase() == 'outside') {
      return MonitoringState.outside;
    } else if (state.toLowerCase() == 'unknown') {
      return MonitoringState.unknown;
    }

    return null;
  }

  /// Parsing dynamic event into [MonitoringEventType]
  static MonitoringEventType _parseMonitoringEventType(dynamic event) {
    if (event == 'didEnterRegion') {
      return MonitoringEventType.didEnterRegion;
    } else if (event == 'didExitRegion') {
      return MonitoringEventType.didExitRegion;
    } else if (event == 'didDetermineStateForRegion') {
      return MonitoringEventType.didDetermineStateForRegion;
    }

    throw Exception('invalid monitoring event type $event');
  }

  /// Return the serializable of this object into [Map].
  dynamic get toJson {
    final map = <String, dynamic>{
      'event': monitoringEventType.toString().split('.').last,
      'region': region.toJson,
    };

    if (monitoringState != null) {
      map['state'] = monitoringState.toString().split('.').last;
    }

    return map;
  }
}
