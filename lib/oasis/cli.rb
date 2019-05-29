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
        matched = false

        parsed_api['paths'].keys.each do |path|
          path_parts = path.split('/')
          parsed_path = path_parts.map do |path_part|
            path_part =~ /^\{([A-Za-z0-9]+)\}$/ ? '[^\/]+' : path_part
          end.join('\/')

          matched = true if req.path =~ Regexp.new("^#{parsed_path}$")
        end

        response = {
          matched: matched,
          method: req.request_method,
          path: req.path,
          api_paths: parsed_api['paths'].keys
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
