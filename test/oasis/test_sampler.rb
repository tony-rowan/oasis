# frozen_string_literal: true

require File.expand_path('../test_helper.rb', __dir__)

class TestSampler < Minitest::Test

  def test_sampler_can_sample_string
    assert_equal sampler.sample(
      'type' => 'string'
    ), 'string'
  end

  def test_sampler_can_sample_boolean
    assert_equal sampler.sample(
      'type' => 'boolean'
    ), true
  end

  def test_sampler_can_sample_number
    assert_equal sampler.sample(
      'type' => 'number'
    ), 3.14
  end

  private

  def sampler
    Oasis::Sampler.new({})
  end

end
