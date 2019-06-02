# frozen_string_literal: true

require 'json'
require 'thor'
require 'webrick'
require 'yaml'

module Oasis

  class Parser

    attr_reader :api_document_file, :force_json, :force_yaml

    def initialize(api_document_file, force_json, force_yaml)
      @api_document_file = api_document_file
      @force_json = force_json
      @force_yaml = force_yaml
    end

    def api_document!
      return JSON.parse(File.read(api_document_file)) if json?
      return YAML.safe_load(File.read(api_document_file)) if yaml?

      raise 'Unkown file type'
    end

    def json?
      force_json ||
        api_document_file_extension == '.json'
    end

    def yaml?
      force_yaml ||
        api_document_file_extension == '.yaml' ||
        api_document_file_extension == '.yml'
    end

    def api_document_file_extension
      @api_document_file_extension ||= File.extname(api_document_file)
    end
  end

  class Server
    attr_reader :api_document

    def initialize(api_document)
      @api_document = api_document
    end

    def respond(request, response)
      # Check for exact matches first
      api_document['paths'].each do |path, path_data|
        next unless request.path == path

        operation_data = path_data[request.request_method.downcase]
        if operation_data.nil?
          response.status = 405
        else
          response.body = sample(
            operation_data['responses']['200']['schema']
          ).to_json.to_s
        end

        return response
      end

      # Check for path parameter matches, using a regex
      api_document['paths'].each do |path, path_data|
        path_parts = path.split('/')
        parsed_path = path_parts.map do |path_part|
          path_part =~ /^\{([A-Za-z0-9]+)\}$/ ? '[^\/]+' : path_part
        end.join('\/')

        next unless request.path =~ Regexp.new("^#{parsed_path}$")

        operation_data = path_data[request.request_method.downcase]
        if operation_data.nil?
          response.status = 405
        else
          response.body = sample(
            operation_data['responses']['200']['schema']
          ).to_json.to_s
        end

        return response
      end

      response.status = 404
    end

    def sample(schema)
      if schema['$ref']
        {
          'reference' => schema['$ref']
        }
      else
        case schema['type']
        when 'array'
          [sample(schema['items']), sample(schema['items'])]
        when 'object'
          data = {}
          schema['properties']&.each do |property_name, property_data|
            data[property_name] = sample(property_data)
          end
          if schema['additionalProperties']
            data['additionalProp0'] = sample(schema['additionalProperties'])
            data['additionalProp1'] = sample(schema['additionalProperties'])
            data['additionalProp2'] = sample(schema['additionalProperties'])
          end
          data
        when 'string'
          'string'
        when 'boolean'
          true
        when 'number'
          3.14
        when 'integer'
          99
        end
      end
    end
  end

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
    def mock(api_document_file)
      # Parse the file on start up to early warn of problems
      Parser.new(api_document_file, options[:json], options[:yaml])
        .api_document!

      server = WEBrick::HTTPServer.new(
        Host: options[:host],
        Port: options[:port]
      )

      server.mount_proc '/' do |request, response|
        # Allow live reload by parsing the file on every request
        parser = Parser.new(api_document_file, options[:json], options[:yaml])
        mock_server = Server.new(parser.api_document!)
        mock_server.respond(request, response)
      end

      %w[INT TERM].each do |signal|
        trap(signal) { server.shutdown }
      end

      server.start
    end

  end

end
