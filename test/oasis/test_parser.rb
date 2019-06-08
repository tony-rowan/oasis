# frozen_string_literal: true

require File.expand_path('../test_helper.rb', __dir__)

class TestParser < Minitest::Test
  def test_that_parser_can_detect_json
    parser = Oasis::Parser.new('some_file.json', false, false)
    assert parser.json?
  end
end
