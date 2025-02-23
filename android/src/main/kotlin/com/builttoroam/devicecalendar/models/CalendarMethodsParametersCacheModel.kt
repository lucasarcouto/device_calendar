package com.builttoroam.devicecalendar.models

import io.flutter.plugin.common.MethodChannel

class CalendarMethodsParametersCacheModel(val pendingChannelResult: MethodChannel.Result,
                                          val calendarDelegateMethodCode: Int,
                                          var calendarId: String = "",
                                          var calendarEventsStartDate: Long? = null,
                                          var calendarEventsEndDate: Long? = null,
                                          var calendarEventsIds: List<String> = listOf(),
                                          var calendarEventId: String? = null,
                                          var calendarEventsIdsSync: List<String> = listOf(),
                                          var calendarEventIdSync: String? = null,
                                          var eventId: String = "",
                                          var event: Event? = null) {
    var ownCacheKey: Int? = null
}