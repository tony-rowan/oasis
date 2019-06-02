# frozen_string_literal: true

require 'json'

module Oasis
  class Sampler
    attr_reader :api_document

    def initialize(api_document)
      @api_document = api_document
    end

    def mock(request, response)
      path = find_path(request)
      response.status = 404 && return unless path

      operation = path[request.request_method.downcase]
      response.status = 405 && return unless operation

      response.body = sample(
        operation['responses']['200']['schema']
      ).to_json.to_s
    end

    def find_path(request)
      api_document['paths'].each do |path, path_data|
        return path_data if request.path == path
      end

      api_document['paths'].each do |path, path_data|
        parsed_path = path.split('/').map do |path_part|
          path_part =~ /^\{([A-Za-z0-9]+)\}$/ ? '[^\/]+' : path_part
        end.join('\/')

        return path_data if request.path =~ Regexp.new("^#{parsed_path}$")
      end

      nil
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
