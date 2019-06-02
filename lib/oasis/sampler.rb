# frozen_string_literal: true

require 'json'

module Oasis
  class Sampler
    attr_reader :api_document

    def initialize(api_document)
      @api_document = api_document
    end

    def mock(request, response)
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
        reference_schema = api_document
        schema['$ref'].split('/').each do |part|
          # A '#' signifies the definition is to be found within this document,
          # which is the only thing we support anyway
          next if part == '#'

          reference_schema = reference_schema[part]
        end
        sample(reference_schema)
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
end
