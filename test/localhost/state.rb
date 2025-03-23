# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2024, by Samuel Williams.
# Copyright, 2021, by Ye Lin Aung.
# Copyright, 2024, by Colin Shea.
# Copyright, 2024, by Aurel Branzeanu.

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
