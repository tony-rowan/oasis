# frozen_string_literal: true

require 'json'
require 'thor'
require 'webrick'
require 'yaml'

module Oasis

  class CLI < Thor
    package_name 'Oasis'

    option :host, aliases: '-h', default: '0.0.0.0',
      desc: 'Mock server will listen on this host'
    option :port, aliases: '-p', default: 3000, type: :numeric,
      desc: 'Mock server will listen on this port'
    desc 'mock FILE', 'Start a server to mock the API specified in FILE'
    def mock(file)
      string_api = File.read(file)
      parsed_api = nil
      begin
        parsed_api = JSON.parse(string_api)
      rescue JSON::ParserError
        begin
          parsed_api = YAML.safe_load(string_api)
        rescue Psych::SyntaxError
          raise "Input file '#{file}' is not JSON or YAML"
        end
      end

      server = WEBrick::HTTPServer.new(
        Host: options[:host],
        Port: options[:port]
      )

      server.mount_proc '/' do |req, res|
        response = {
          method: req.request_method,
          path: req.path,
          api_paths: parsed_api['paths']
        }
        res.body = response.to_json.to_s
      end

      %w[INT TERM].each do |signal|
        trap(signal) { server.shutdown }
      end

      server.start
    end

  end

end
