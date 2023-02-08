# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023, by Samuel Williams.

require 'localhost'

describe Localhost do
	it "has a version number" do
		expect(Localhost::VERSION).to be =~ /\d+\.\d+\.\d+/
	end
end
