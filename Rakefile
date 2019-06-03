# frozen_string_literal: true

desc 'Run all the tests'
task default: %I[minitest integration_tests]

desc 'Run all of the unit tests'
task :minitest do
  ruby(FileList['test/minitest/*.rb'])
end

desc 'Run the integration tests'
task :integration_tests do
  FileList['test/integration/*.rb'].each do |integration_test_file|
    puts '---'
    ruby(integration_test_file)
    puts '---'
  end
end
