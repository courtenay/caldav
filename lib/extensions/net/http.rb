require 'digest/md5'

module Net #:nodoc:
  class HTTP #:nodoc:
    
    class Mkcalendar < HTTPRequest
      METHOD = 'MKCALENDAR'
      REQUEST_HAS_BODY = true
      RESPONSE_HAS_BODY = true
    end
    
    class Report < HTTPRequest
      METHOD = 'REPORT'
      REQUEST_HAS_BODY = true
      RESPONSE_HAS_BODY = true
    end
    
  end
  
  # from http://codesnippets.joyent.com/posts/show/1075
  module HTTPHeader
    @@nonce_count = -1
    CNONCE = Digest::MD5.new.update("%x" % (Time.now.to_i + rand(65535))).hexdigest
    def digest_auth(user, password, response)
      # based on http://segment7.net/projects/ruby/snippets/digest_auth.rb

      response['www-authenticate'] =~ /^(\w+) (.*)/

      params = {}
      $2.gsub(/(\w+)="(.*?)"/) { params[$1] = $2 }

      a_1 = "#{user}:#{params['realm']}:#{password}"
      a_2 = "#{@method}:#{@path}"
      
      if params['qop'].nil?
        # from http://code.activestate.com/recipes/302378/
        request_digest = ''
        request_digest << Digest::MD5.new.update(a_1).hexdigest
        request_digest << ':' << params['nonce']
        request_digest << ':' << Digest::MD5.new.update(a_2).hexdigest        
      else
        @@nonce_count += 1
        request_digest = ''
        request_digest << Digest::MD5.new.update(a_1).hexdigest
        request_digest << ':' << params['nonce']
        request_digest << ':' << ('%08x' % @@nonce_count)
        request_digest << ':' << CNONCE
        request_digest << ':' << params['qop']
        request_digest << ':' << Digest::MD5.new.update(a_2).hexdigest
      end

      header = []
      header << "Digest username=\"#{user}\""
      header << "realm=\"#{params['realm']}\""

      header << "qop=#{params['qop']}" if params['qop']
      header << "algorithm=MD5"
      header << "nonce=\"#{params['nonce']}\""
      header << "uri=\"#{@path}\""
      if params['qop']        
        header << "nc=#{'%08x' % @@nonce_count}"
        header << "cnonce=\"#{CNONCE}\""
      end
      header << "response=\"#{Digest::MD5.new.update(request_digest).hexdigest}\""

      @header['Authorization'] = header
    end
  end
end