# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2024, by Samuel Williams.

source 'https://rubygems.org'

gemspec

group :maintenance, optional: true do
	gem "bake-gem"
	gem "bake-modernize"
	
	gem "utopia-project"
end

group :test do
	gem "sus", "~> 0.16"
	gem "sus-fixtures-async"
	gem "covered"
	
	gem "bake-test"
	gem "bake-test-external"
	
	gem 'async-io'
	gem 'async-process'
end
