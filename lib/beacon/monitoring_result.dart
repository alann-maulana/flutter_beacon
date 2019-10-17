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
  final MonitoringState monitoringState;

  /// The [Region] of ranging result.
  final Region region;

  /// Constructor for deserialize dynamic json into [MonitoringResult].
  MonitoringResult._from(dynamic json)
      : this.monitoringEventType = _parseMonitoringEventType(json['event']),
        this.monitoringState = _parseMonitoringState(json['state']),
        this.region = Region.fromJson(json['region']);

  /// Parsing dynamic state into [MonitoringState].
  static MonitoringState _parseMonitoringState(dynamic state) {
    if (state == 'INSIDE') {
      return MonitoringState.inside;
    } else if (state == 'OUTSIDE') {
      return MonitoringState.outside;
    } else if (state == 'UNKNOWN') {
      return MonitoringState.unknown;
    }

    return null;
  }

  // Parsing dynamic event into [MonitoringEventType]
  static MonitoringEventType _parseMonitoringEventType(dynamic event) {
    if (event == 'didEnterRegion') {
      return MonitoringEventType.didEnterRegion;
    } else if (event == 'didExitRegion') {
      return MonitoringEventType.didExitRegion;
    } else if (event == 'didDetermineStateForRegion') {
      return MonitoringEventType.didDetermineStateForRegion;
    }

    return null;
  }
}
