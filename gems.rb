# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

group :maintenance, optional: true do
	gem "bake-gem"
	gem "bake-modernize"
	
	gem "utopia-project"
end

group :development do
	gem 'async-io'
	gem 'async-rspec'
	
	gem 'async-process'
end
