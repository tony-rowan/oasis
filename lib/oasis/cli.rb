# frozen_string_literal: true

require 'thor'

module Oasis
  class CLI < Thor
    package_name 'Oasis'

    option :host, aliases: '-h', default: '0.0.0.0',
      desc: 'Mock server will listen on this host'
    option :port, aliases: '-p', default: 3000, type: :numeric,
      desc: 'Mock server will listen on this port'
    option :json, aliases: '-j', type: :boolean,
      desc: 'Force parsing the api document as JSON'
    option :yaml, aliases: '-y', type: :boolean,
      desc: 'Force parsing the api document as YMAL'
    desc 'mock FILE', 'Start a server to mock the API specified in FILE'
    def mock(api_document_file)
      parser = Parser.new(api_document_file, options[:json], options[:yaml])
      # Parse the file before serving to detect problems early
      parser.api_document!
      Server.new(parser, options[:host], options[:port]).serve
    end

  end
end
