# frozen_string_literal: true

require 'json'
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
end
