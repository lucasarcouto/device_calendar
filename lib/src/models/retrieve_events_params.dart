class RetrieveEventsParams {
  final List<String>? eventIds;
  final List<String>? eventIdsSync;
  final DateTime? startDate;
  final DateTime? endDate;

  const RetrieveEventsParams(
      {this.eventIds, this.eventIdsSync, this.startDate, this.endDate});
}
