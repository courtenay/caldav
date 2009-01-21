module CalDAV
  
  class Calendar
    attr_accessor :uri, :options

    def initialize(uri, options = {})
      self.uri = URI.parse(uri)
      raise "You must provide username/pass" if options[:username].nil? || options[:password].nil?
      self.options = options
    end
    
    # # Create a new calendar
    # #
    # # == Options
    # #
    # # * <tt>:displayname</tt>: A display name for the calendar
    # # * <tt>:description</tt>: A description for the calendar
    # # * <tt>:username</tt>: Username used for authentication
    # # * <tt>:password</tt>: Password used for authentication
    # #
    # def self.create(uri, options = {})
    #   parsed_uri = URI.parse(uri)
    #   response = Net::HTTP.start(parsed_uri.host, parsed_uri.port) do |http|
    #     request = Net::HTTP::Mkcalendar.new(parsed_uri.path)
    #     request.body = CalDAV::Request::Mkcalendar.new(options[:displayname], options[:description]).to_xml
    #     request.basic_auth options[:username], options[:password] unless options[:username].blank? && options[:password].blank?
    #     http.request request
    #   end
    #   raise CalDAV::Error.new(response.message, response) if response.code != '201'
    #   self.new(uri, options)
    # end
    #   
    # def delete
    #   perform_request Net::HTTP::Delete
    # end
    # 
    
    def properties
      perform_request Net::HTTP::Propfind
    end
    
    def load_events(params)
      response = load_events_xml params
      xml = parse_events_xml
      events = []
      xml.map do |event|
        ics = request_ics_from_event(event)
        extract_events_from_ics(ics)
      end
    end

private
    
    # Load the Calendar x.500 or xml or whatever the hell it is
    def load_events_xml(param)
      request = new_request Net::HTTP::Report do |request|
        request.body = CalendarQuery.new.event(param).to_xml
      end
      @response = perform_request request
    end
    
    # Find all the events in the big xml chunk
    def parse_events_xml
      h = Hpricot @response.body
      r = h/:response
      r[1..-1]
    end
    
    # find the href to the .ics file and load it
    def request_ics_from_event(event)
      ics_path = (event/:href).text
      load_ics(ics_path)
    end
    
    # parse the .ics file and find the first event in it
    def extract_events_from_ics(ics)
      ical = Icalendar::Parser.new(ics).parse.first
      # assumes one event per ics, bah
      ical.events[0]
    end

    # load the ics from the original host
    def load_ics(path)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      response = http.start do |http|
        # todo : DRY this crap
        res = http.head(path)
        req = Net::HTTP::Get.new path
        req.digest_auth options[:username], options[:password], res
        response = http.request req
      end
      response.body
    end

    #def add_event(calendar)
    #  request = Net::HTTP::Put.new("#{uri.path}/#{calendar.events.first.uid}.ics")
    #  request.add_field "If-None-Match", "*"
    #  request.body = calendar.to_ical
    #  response = perform_request request
    #  raise CalDAV::Error.new(response.message, response) if response.code != '201'
    #  true
    #end
    
   # # This is busted - c3
   # # TODO: check that supported-report-set includes REPORT
   # def events(param)
   #   response = load_events_xml
   #   events = []
   #   
   #   body = REXML::Document.new(response.body)
   #   body.root.add_namespace 'dav', 'DAV:'
   #   body.root.add_namespace 'caldav', 'urn:ietf:params:xml:ns:caldav'
   # 
   #   body.elements.each("dav:multistatus/dav:response") do |element|
   #     href = element.elements['href'].text
   #     uri.path = href
   #     response = perform_request request 
   # 
   #     calendar = Icalendar::Parser.new(element.elements["dav:propstat/dav:prop/caldav:calendar-data"].text).parse.first
   #     
   #     calendar.events.each do |event|
   #       event.caldav = {
   #         :etag => element.elements["dav:propstat/dav:prop/dav:getetag"].text, 
   #         :href => element.elements["dav:href"].text
   #       }
   #     events += calendar.events
   #     end
   #   end
   #   
   #   events
   # end
    
    def new_request(clazz, &block)
      returning clazz.new(uri.path) do |request|
        yield request if block_given?
      end
    end
    
    def prepare_request(request)
      request.digest_auth options[:username], options[:password]
      request
    end
    
    def perform_request(request)
      request = new_request(request) if request.is_a? Class
      
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.start do |http|
        res = http.head(uri.request_uri)
        req = Net::HTTP::Propfind.new uri.path
        req.digest_auth options[:username], options[:password], res
        response = http.request req
      end
    end

  end
end