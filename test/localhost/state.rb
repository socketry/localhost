# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "localhost/authority"

require "sus/fixtures/async/reactor_context"
require "io/endpoint/ssl_endpoint"

require "fileutils"
require "tempfile"

describe Localhost::State do
	with ".path" do
		it "uses XDG_STATE_HOME" do
			env = {"XDG_STATE_HOME" => "/tmp/state"}
			
			expect(Localhost::State.path(env)).to be == File.expand_path("localhost.rb", "/tmp/state")
		end
	end
end
