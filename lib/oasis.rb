# frozen_string_literal: true

require 'json'
require 'thor'
require 'webrick'
require 'yaml'

module Oasis

  class Main < Thor
    package_name 'Oasis'

    attr_reader :parsed_api

    option :host, aliases: '-h', default: '0.0.0.0',
      desc: 'Mock server will listen on this host'
    option :port, aliases: '-p', default: 3000, type: :numeric,
      desc: 'Mock server will listen on this port'
    desc 'mock FILE', 'Start a server to mock the API specified in FILE'
    def mock(file)
      string_api = File.read(file)
      @parsed_api = nil
      begin
        @parsed_api = JSON.parse(string_api)
      rescue JSON::ParserError
        begin
          @parsed_api = YAML.safe_load(string_api)
        rescue Psych::SyntaxError
          raise "Input file '#{file}' is not JSON or YAML"
        end
      end

      server = WEBrick::HTTPServer.new(
        Host: options[:host],
        Port: options[:port]
      )

      server.mount_proc '/' do |request, response|
        respond(request, response)
      end

      %w[INT TERM].each do |signal|
        trap(signal) { server.shutdown }
      end

      server.start
    end

    def respond(request, response)
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
