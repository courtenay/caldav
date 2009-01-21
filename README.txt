= CalDAV

This is a hacked up version of the CalDAV library that is designed to work with my XServe's iCal server.
It implements digest auth (instead of basic) and grabs individual .ics files because I couldn't find a way
to see prop/caldav:calendar-data in the feed.

Requirements:

Gems:
  icalendar
  tzinfo
  