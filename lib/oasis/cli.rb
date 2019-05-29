# frozen_string_literal: true

require 'thor'

module Oasis

  class CLI < Thor

    desc 'mock FILE', 'Start a server to mock the API specified in FILE'
    def mock(file)
    end

  end

end
