require 'json'
require 'net/http'
require 'uri'

module Haste

  DEFAULT_URL = 'http://hastebin.com'

  class CLI

    # Pull all of the data from STDIN
    def initialize
      if STDIN.tty?
        abort 'No input file given' unless ARGV.length == 1
        abort "#{file}: No such path" unless File.exists?(file = ARGV[0])
        @input = open(file).read
      else
        @input = STDIN.readlines.join
      end
      # clean up
      @input.strip!
    end

    # Upload the and output the URL we get back
    def start
      uri = URI.parse server
      http = Net::HTTP.new uri.host, uri.port
      response = http.post '/documents', @input
      if response.is_a?(Net::HTTPOK)
        data = JSON.parse(response.body)
        method = STDOUT.tty? ? :puts : :print
        STDOUT.send method, "#{server}/#{data['key']}"
      else
        abort "failure uploading: #{response.code}"
      end
    rescue JSON::ParserError => e
      abort "failure uploading: #{response.code}"
    rescue Errno::ECONNREFUSED => e
      abort "failure connecting: #{e.message}"
    end

    private

    def server
      return @server if @server
      @server = ENV['HASTE_SERVER'].dup || Haste::DEFAULT_URL
      @server.chop! if server.end_with?('/')
      @server
    end

  end

end
