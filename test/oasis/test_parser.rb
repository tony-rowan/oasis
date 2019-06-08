# frozen_string_literal: true

require File.expand_path('../test_helper.rb', __dir__)

class TestParser < Minitest::Test
  def test_that_parser_can_detect_json
    parser = Oasis::Parser.new('some_file.json')
    assert parser.json?
    refute parser.yaml?
  end

  def test_that_parser_will_accept_force_json
    parser = Oasis::Parser.new('some_file.exe', force_json: true)
    assert parser.json?
    refute parser.yaml?
  end

  def test_that_parser_can_detect_yaml
    parser = Oasis::Parser.new('some_file.yml')
    refute parser.json?
    assert parser.yaml?
  end

  def test_that_parser_will_accept_force_yaml
    parser = Oasis::Parser.new('some_file.exe', force_yaml: true)
    refute parser.json?
    assert parser.yaml?
  end

  def test_that_parser_can_parse_json
    parser = Oasis::Parser.new('./test/sample/petstore.json')
    doc = parser.api_document!
    assert_equal doc['info']['title'], 'Swagger Petstore'
  end

  def test_that_parser_can_parse_yaml
    parser = Oasis::Parser.new('./test/sample/petstore.yaml')
    doc = parser.api_document!
    assert_equal doc['info']['title'], 'Swagger Petstore'
  end

  def test_that_parse_will_throw_error_on_parsing_failure
    parser = Oasis::Parser.new('./test/sample/petstore.out')
    assert_raises('Unkown file type') { parser.api_document! }
  end
end
