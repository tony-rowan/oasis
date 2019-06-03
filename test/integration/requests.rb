# frozen_string_literal: true

require 'http'

def run_tests
  # Start the mock server against the petstore sample
  server_process_id = spawn(
    './bin/oasis mock --port 3001 ./test/sample/petstore.yml'
  )
  sleep 2 # It takes a few seconds to start
  puts "Spawned Server: #{server_process_id}"

  # Test a simple GET request for a resource
  response = HTTP.get('http://localhost:3001/pet/123')
  unless response.code == 200
    raise "Failed known good GET request - #{response.status}: #{response}"
  end

  # Test a known failure state:
  # No '200' response defined for a more complicated resource
  response = HTTP.post('http://localhost:3001/pet', json: { id: 0 })
  unless response.code == 400
    raise "Failed known failure POST request - #{response.status}: #{response}"
  end

  puts 'All requests successful'
ensure
  Process.kill('SIGTERM', server_process_id)
end

run_tests
