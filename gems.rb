# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2025, by Samuel Williams.

source "https://rubygems.org"

gemspec

group :maintenance, optional: true do
	gem "bake-gem"
	gem "bake-modernize"
	gem "bake-releases"
	
	gem "utopia-project"
end

group :test do
	gem "sus"
	gem "covered"
	gem "decode"
	
	gem "rubocop"
	gem "rubocop-socketry"
	
	gem "io-endpoint"
	gem "sus-fixtures-async"
	gem "sus-fixtures-async-http"
	
	gem "bake-test"
	gem "bake-test-external"
end
