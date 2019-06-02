# frozen_string_literal: true

require 'webrick'

module Oasis
  class Server

    attr_reader :parser, :host, :port

    def initialize(parser, host, port)
      @parser = parser
      @host = host
      @port = port
    end

    def serve
      server = WEBrick::HTTPServer.new(Host: host, Port: port)

      server.mount_proc '/' do |request, response|
        # Allow live reload by parsing the file on every request
        Sampler.new(parser.api_document!).mock(request, response)
      end

      %w[INT TERM].each do |signal|
        trap(signal) { server.shutdown }
      end

      server.start
    end

  end
end
