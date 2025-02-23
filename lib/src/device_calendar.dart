import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sprintf/sprintf.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart';

import 'common/channel_constants.dart';
import 'common/error_codes.dart';
import 'common/error_messages.dart';
import 'models/calendar.dart';
import 'models/event.dart';
import 'models/result.dart';
import 'models/retrieve_events_params.dart';

/// Provides functionality for working with device calendar(s)
class DeviceCalendarPlugin {
  static const MethodChannel channel =
      MethodChannel(ChannelConstants.channelName);

  static final DeviceCalendarPlugin _instance = DeviceCalendarPlugin.private();

  factory DeviceCalendarPlugin({bool shouldInitTimezone = true}) {
    if (shouldInitTimezone) {
      tz.initializeTimeZones();
    }
    return _instance;
  }

  @visibleForTesting
  DeviceCalendarPlugin.private();

  /// Requests permissions to modify the calendars on the device
  ///
  /// Returns a [Result] indicating if calendar READ and WRITE permissions
  /// have (true) or have not (false) been granted
  Future<Result<bool>> requestPermissions() async {
    return _invokeChannelMethod(
      ChannelConstants.methodNameRequestPermissions,
    );
  }

  /// Checks if permissions for modifying the device calendars have been granted
  ///
  /// Returns a [Result] indicating if calendar READ and WRITE permissions
  /// have (true) or have not (false) been granted
  Future<Result<bool>> hasPermissions() async {
    return _invokeChannelMethod(
      ChannelConstants.methodNameHasPermissions,
    );
  }

  /// Retrieves all of the device defined calendars
  ///
  /// Returns a [Result] containing a list of device [Calendar]
  Future<Result<UnmodifiableListView<Calendar>>> retrieveCalendars() async {
    return _invokeChannelMethod(
      ChannelConstants.methodNameRetrieveCalendars,
      evaluateResponse: (rawData) => UnmodifiableListView(
        json.decode(rawData).map<Calendar>(
              (decodedCalendar) => Calendar.fromJson(decodedCalendar),
            ),
      ),
    );
  }

  /// Retrieves the events from the specified calendar
  ///
  /// The `calendarId` parameter is the id of the calendar that plugin will return events for
  /// The `retrieveEventsParams` parameter combines multiple properties that
  /// specifies conditions of the events retrieval. For instance, defining [RetrieveEventsParams.startDate]
  /// and [RetrieveEventsParams.endDate] will return events only happening in that time range
  ///
  /// Returns a [Result] containing a list [Event], that fall
  /// into the specified parameters
  Future<Result<UnmodifiableListView<Event>>> retrieveEvents(
    String? calendarId,
    RetrieveEventsParams? retrieveEventsParams,
  ) async {
    return _invokeChannelMethod(
      ChannelConstants.methodNameRetrieveEvents,
      assertParameters: (result) {
        _validateCalendarIdParameter(
          result,
          calendarId,
        );

        _assertParameter(
          result,
          !((retrieveEventsParams?.eventIds?.isEmpty ?? true) &&
              !(retrieveEventsParams?.eventIdsSync?.isEmpty ?? true) &&
              ((retrieveEventsParams?.startDate == null ||
                      retrieveEventsParams?.endDate == null) ||
                  (retrieveEventsParams?.startDate != null &&
                      retrieveEventsParams?.endDate != null &&
                      (retrieveEventsParams != null &&
                          retrieveEventsParams.startDate!
                              .isAfter(retrieveEventsParams.endDate!))))),
          ErrorCodes.invalidArguments,
          ErrorMessages.invalidRetrieveEventsParams,
        );
      },
      arguments: () => <String, Object?>{
        ChannelConstants.parameterNameCalendarId: calendarId,
        ChannelConstants.parameterNameStartDate:
            retrieveEventsParams?.startDate?.millisecondsSinceEpoch,
        ChannelConstants.parameterNameEndDate:
            retrieveEventsParams?.endDate?.millisecondsSinceEpoch,
        ChannelConstants.parameterNameEventIds: retrieveEventsParams?.eventIds,
        ChannelConstants.parameterNameEventIdsSync:
            retrieveEventsParams?.eventIdsSync,
      },
      evaluateResponse: (rawData) => UnmodifiableListView(
        json
            .decode(rawData)
            .map<Event>((decodedEvent) => Event.fromJson(decodedEvent)),
      ),
    );
  }

  /// Retrieves the event which has the specified eventId or eventSyncId
  ///
  /// Returns a [Result] containing an [Event], that fall
  /// into the specified parameters
  Future<Result<Event>> retrieveEvent(
    RetrieveEventsParams? retrieveEventsParams,
  ) async {
    return _invokeChannelMethod(
      ChannelConstants.methodNameRetrieveEvent,
      assertParameters: (result) {
        _assertParameter(
          result,
          !((retrieveEventsParams?.eventId?.isEmpty ?? true) &&
              (retrieveEventsParams?.eventIdSync?.isEmpty ?? true) &&
              (retrieveEventsParams?.calendarId?.isEmpty ?? true)),
          ErrorCodes.invalidArguments,
          ErrorMessages.invalidRetrieveEventsParams,
        );
      },
      arguments: () => <String, Object?>{
        ChannelConstants.parameterNameCalendarId:
            retrieveEventsParams?.calendarId,
        ChannelConstants.parameterNameEventId: retrieveEventsParams?.eventId,
        ChannelConstants.parameterNameEventIdSync:
            retrieveEventsParams?.eventIdSync,
      },
      evaluateResponse: (rawData) => Event.fromJson(json.decode(rawData)),
    );
  }

  /// Deletes an event from a calendar. For a recurring event, this will delete all instances of it.\
  /// To delete individual instance of a recurring event, please use [deleteEventInstance()]
  ///
  /// The `calendarId` parameter is the id of the calendar that plugin will try to delete the event from\
  /// The `eventId` parameter is the id of the event that plugin will try to delete
  ///
  /// Returns a [Result] indicating if the event has (true) or has not (false) been deleted from the calendar
  Future<Result<bool>> deleteEvent(
    String? calendarId,
    String? eventId,
  ) async {
    return _invokeChannelMethod(
      ChannelConstants.methodNameDeleteEvent,
      assertParameters: (result) {
        _validateCalendarIdParameter(
          result,
          calendarId,
        );

        _assertParameter(
          result,
          eventId?.isNotEmpty ?? false,
          ErrorCodes.invalidArguments,
          ErrorMessages.deleteEventInvalidArgumentsMessage,
        );
      },
      arguments: () => <String, Object?>{
        ChannelConstants.parameterNameCalendarId: calendarId,
        ChannelConstants.parameterNameEventId: eventId,
      },
    );
  }

  /// Deletes an instance of a recurring event from a calendar. This should be used for a recurring event only.\
  /// If `startDate`, `endDate` or `deleteFollowingInstances` is not valid or null, then all instances of the event will be deleted.
  ///
  /// The `calendarId` parameter is the id of the calendar that plugin will try to delete the event from\
  /// The `eventId` parameter is the id of the event that plugin will try to delete\
  /// The `startDate` parameter is the start date of the instance to delete\
  /// The `endDate` parameter is the end date of the instance to delete\
  /// The `deleteFollowingInstances` parameter will also delete the following instances if set to true
  ///
  /// Returns a [Result] indicating if the instance of the event has (true) or has not (false) been deleted from the calendar
  Future<Result<bool>> deleteEventInstance(
    String? calendarId,
    String? eventId,
    int? startDate,
    int? endDate,
    bool deleteFollowingInstances,
  ) async {
    return _invokeChannelMethod(
      ChannelConstants.methodNameDeleteEventInstance,
      assertParameters: (result) {
        _validateCalendarIdParameter(
          result,
          calendarId,
        );

        _assertParameter(
          result,
          eventId?.isNotEmpty ?? false,
          ErrorCodes.invalidArguments,
          ErrorMessages.deleteEventInvalidArgumentsMessage,
        );
      },
      arguments: () => <String, Object?>{
        ChannelConstants.parameterNameCalendarId: calendarId,
        ChannelConstants.parameterNameEventId: eventId,
        ChannelConstants.parameterNameEventStartDate: startDate,
        ChannelConstants.parameterNameEventEndDate: endDate,
        ChannelConstants.parameterNameFollowingInstances:
            deleteFollowingInstances,
      },
    );
  }

  /// Creates or updates an event
  ///
  /// The `event` paramter specifies how event data should be saved into the calendar
  /// Always specify the [Event.calendarId], to inform the plugin in which calendar
  /// it should create or update the event.
  ///
  /// Returns a [Result] with the newly created or updated [Event.eventId]
  Future<Result<String>?> createOrUpdateEvent(Event? event) async {
    if (event == null) return null;
    return _invokeChannelMethod(
      ChannelConstants.methodNameCreateOrUpdateEvent,
      assertParameters: (result) {
        // Setting time to 0 for all day events
        if (event.allDay == true) {
          if (event.start != null) {
            var dateStart = DateTime(event.start!.year, event.start!.month,
                event.start!.day, 0, 0, 0);
            // allDay events on Android need to be at midnight UTC
            event.start = Platform.isAndroid
                ? TZDateTime.utc(event.start!.year, event.start!.month,
                    event.start!.day, 0, 0, 0)
                : TZDateTime.from(dateStart,
                    timeZoneDatabase.locations[event.start!.location.name]!);
          }
          if (event.end != null) {
            var dateEnd = DateTime(
                event.end!.year, event.end!.month, event.end!.day, 0, 0, 0);
            // allDay events on Android need to be at midnight UTC on the
            // day after the last day. For example, a 2-day allDay event on
            // Jan 1 and 2, should be from Jan 1 00:00:00 to Jan 3 00:00:00
            event.end = Platform.isAndroid
                ? TZDateTime.utc(event.end!.year, event.end!.month,
                        event.end!.day, 0, 0, 0)
                    .add(Duration(days: 1))
                : TZDateTime.from(dateEnd,
                    timeZoneDatabase.locations[event.end!.location.name]!);
          }
        }

        _assertParameter(
          result,
          !(event.allDay == true && (event.calendarId?.isEmpty ?? true) ||
              event.start == null ||
              event.end == null),
          ErrorCodes.invalidArguments,
          ErrorMessages.createOrUpdateEventInvalidArgumentsMessageAllDay,
        );

        _assertParameter(
          result,
          !(event.allDay != true &&
              ((event.calendarId?.isEmpty ?? true) ||
                  event.start == null ||
                  event.end == null ||
                  (event.start != null &&
                      event.end != null &&
                      event.start!.isAfter(event.end!)))),
          ErrorCodes.invalidArguments,
          ErrorMessages.createOrUpdateEventInvalidArgumentsMessage,
        );
      },
      arguments: () => event.toJson(),
    );
  }

  /// Creates a new local calendar for the current device.
  ///
  /// The `calendarName` parameter is the name of the new calendar\
  /// The `calendarColor` parameter is the color of the calendar. If null,
  /// a default color (red) will be used\
  /// The `localAccountName` parameter is the name of the local account:
  /// - [Android] Required. If `localAccountName` parameter is null or empty, it will default to 'Device Calendar'.
  /// If the account name already exists in the device, it will add another calendar under the account,
  /// otherwise a new local account and a new calendar will be created.
  /// - [iOS] Not used. A local account will be picked up automatically, if not found, an error will be thrown.
  ///
  /// Returns a [Result] with the newly created [Calendar.id]
  Future<Result<String>> createCalendar(
    String? calendarName, {
    Color? calendarColor,
    String? localAccountName,
  }) async {
    return _invokeChannelMethod(
      ChannelConstants.methodNameCreateCalendar,
      assertParameters: (result) {
        calendarColor ??= Colors.red;

        _assertParameter(
          result,
          calendarName?.isNotEmpty == true,
          ErrorCodes.invalidArguments,
          ErrorMessages.createCalendarInvalidCalendarNameMessage,
        );
      },
      arguments: () => <String, Object?>{
        ChannelConstants.parameterNameCalendarName: calendarName,
        ChannelConstants.parameterNameCalendarColor:
            '0x${calendarColor?.value.toRadixString(16)}',
        ChannelConstants.parameterNameLocalAccountName:
            localAccountName?.isEmpty ?? true
                ? 'Device Calendar'
                : localAccountName
      },
    );
  }

  /// Deletes a calendar.
  /// The `calendarId` parameter is the id of the calendar that plugin will try to delete the event from\///
  /// Returns a [Result] indicating if the instance of the calendar has (true) or has not (false) been deleted
  Future<Result<bool>> deleteCalendar(
    String calendarId,
  ) async {
    return _invokeChannelMethod(
      ChannelConstants.methodNameDeleteCalendar,
      assertParameters: (result) {
        _validateCalendarIdParameter(
          result,
          calendarId,
        );
      },
      arguments: () => <String, Object>{
        ChannelConstants.parameterNameCalendarId: calendarId,
      },
    );
  }

  /// Displays a native iOS view [EKEventViewController]
  /// https://developer.apple.com/documentation/eventkitui/ekeventviewcontroller
  ///
  /// Allows to change the event's attendance status
  /// Works only on iOS
  /// Returns after dismissing EKEventViewController's dialog
  Future<Result<void>> showiOSEventModal(
    String eventId,
  ) {
    return _invokeChannelMethod(
      ChannelConstants.methodNameShowiOSEventModal,
      arguments: () => <String, String>{
        ChannelConstants.parameterNameEventId: eventId,
      },
    );
  }

  Future<Result<T>> _invokeChannelMethod<T>(
    String channelMethodName, {
    Function(Result<T>)? assertParameters,
    Map<String, Object?> Function()? arguments,
    T Function(dynamic)? evaluateResponse,
  }) async {
    final result = Result<T>();

    try {
      if (assertParameters != null) {
        assertParameters(result);
        if (result.hasErrors) {
          return result;
        }
      }

      var rawData = await channel.invokeMethod(
        channelMethodName,
        arguments != null ? arguments() : null,
      );

      if (evaluateResponse != null) {
        result.data = evaluateResponse(rawData);
      } else {
        result.data = rawData;
      }
    } catch (e, stack) {
      _parsePlatformExceptionAndUpdateResult<T>(e as Exception?, result);
    }

    return result;
  }

  void _parsePlatformExceptionAndUpdateResult<T>(
      Exception? exception, Result<T> result) {
    if (exception == null) {
      result.errors.add(
        ResultError(
          ErrorCodes.unknown,
          ErrorMessages.unknownDeviceIssue,
        ),
      );
      return;
    }

    print(exception);

    if (exception is PlatformException) {
      result.errors.add(
        ResultError(
          ErrorCodes.platformSpecific,
          sprintf(ErrorMessages.unknownDeviceExceptionTemplate,
              [exception.code, exception.message]),
        ),
      );
    } else {
      result.errors.add(
        ResultError(
          ErrorCodes.generic,
          sprintf(ErrorMessages.unknownDeviceGenericExceptionTemplate,
              [exception.toString()]),
        ),
      );
    }
  }

  void _assertParameter<T>(
    Result<T> result,
    bool predicate,
    int errorCode,
    String errorMessage,
  ) {
    if (!predicate) {
      result.errors.add(
        ResultError(errorCode, errorMessage),
      );
    }
  }

  void _validateCalendarIdParameter<T>(
    Result<T> result,
    String? calendarId,
  ) {
    _assertParameter(
      result,
      calendarId?.isNotEmpty ?? false,
      ErrorCodes.invalidArguments,
      ErrorMessages.invalidMissingCalendarId,
    );
  }
}
