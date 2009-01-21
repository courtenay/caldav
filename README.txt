= CalDAV

This is a hacked up version of the CalDAV library that is designed to work with my XServe's iCal server.
It implements digest auth (instead of basic) and grabs individual .ics files because I couldn't find a way
to see prop/caldav:calendar-data in the feed.

It makes a ton of assumptions :)

Requirements:

Gems:
  icalendar
  tzinfo

Usage:

  require 'caldav'

  options = { :username => 'courtenay', :password => 'blarg' }
  host = "https://whatever.com:443"

  calendar = CalDAV::Calendar.new "#{host}/calendars/users/officecalendar/calendar/", options
  params   = (DateTime.parse("20081202T000000Z")..DateTime.parse("20090103T000000Z"))
    
  response = calendar.load_events_xml params
  # Loads a big chunk of XML. Slooooow
  
  events = calendar.parse_events_xml
  ics = calendar.request_ics_from_event(events[0])
  calendar.extract_events_from_ics(ics)
  
