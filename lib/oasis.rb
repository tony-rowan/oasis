# frozen_string_literal: true

require 'json'
require 'thor'
require 'webrick'
require 'yaml'

module Oasis

  class Main < Thor
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
    def mock(file)
      parsed_api = nil
      string_api = File.read(file)
      extension = File.extname(file)

      if options[:json] || extension == '.json'
        parsed_api = JSON.parse(string_api)
      end

      if options[:yaml] || extension == '.yaml' || extension == '.yml'
        parsed_api = YAML.safe_load(string_api)
      end

      if parsed_api.nil?
        raise 'Could not parse api document'
      end

      server = WEBrick::HTTPServer.new(
        Host: options[:host],
        Port: options[:port]
      )

      server.mount_proc '/' do |request, response|
        respond(parsed_api, request, response)
      end

      %w[INT TERM].each do |signal|
        trap(signal) { server.shutdown }
      end

      server.start
    end

    no_commands do
      def respond(parsed_api, request, response)
        # Check for exact matches first
        parsed_api['paths'].each do |path, path_data|
          next unless request.path == path

          operation_data = path_data[request.request_method.downcase]
          if operation_data.nil?
            response.status = 405
          else
            response.body =
              operation_data['responses']['200']['schema'].to_json.to_s
          end

          return response
        end

        # Check for path parameter matches, using a regex
        parsed_api['paths'].each do |path, path_data|
          path_parts = path.split('/')
          parsed_path = path_parts.map do |path_part|
            path_part =~ /^\{([A-Za-z0-9]+)\}$/ ? '[^\/]+' : path_part
          end.join('\/')

          next unless request.path =~ Regexp.new("^#{parsed_path}$")

          operation_data = path_data[request.request_method.downcase]
          if operation_data.nil?
            response.status = 405
          else
            response.body =
              operation_data['responses']['200']['schema'].to_json.to_s
          end

          return response
        end

        response.status = 404
      end
    end

  end

end
