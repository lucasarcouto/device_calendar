class RetrieveEventsParams {
  final String? calendarId;
  final List<String>? eventIds;
  final String? eventId;
  final List<String>? eventIdsSync;
  final String? eventIdSync;
  final DateTime? startDate;
  final DateTime? endDate;

  const RetrieveEventsParams(
      {this.calendarId,
      this.eventIds,
      this.eventId,
      this.eventIdsSync,
      this.eventIdSync,
      this.startDate,
      this.endDate});
}
