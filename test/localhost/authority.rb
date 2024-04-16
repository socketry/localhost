# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2024, by Samuel Williams.
# Copyright, 2021, by Ye Lin Aung.
# Copyright, 2024, by Colin Shea.

require 'localhost/authority'

require 'sus/fixtures/async/reactor_context'
require 'async/io/host_endpoint'
require 'async/io/ssl_endpoint'
require 'async/io/shared_endpoint'

require 'async/process'
require 'fileutils'
require 'tempfile'

describe Localhost::Authority do
	def around
		Dir.mktmpdir do |path|
			@root = path
			
			yield
		ensure
			@root = nil
		end
	end
	
	let(:authority) {subject.new("localhost", root: @root)}
	
	with ".path" do
		it "uses XDG_STATE_HOME" do
			env = {'XDG_STATE_HOME' => @root}
			
			expect(Localhost::Authority.path(env)).to be == File.expand_path("localhost.rb", @root)
		end
		
		it "copies legacy directory" do
			xdg_state_home = File.join(@root, ".local", "state")
			env = {'XDG_STATE_HOME' => xdg_state_home}
			
			old_root = File.join(@root, ".localhost")
			Dir.mkdir(old_root)
			File.write(File.join(old_root, "localhost.crt"), "*fake certificate*")
			File.write(File.join(old_root, "localhost.key"), "*fake key*")
			
			path = Localhost::Authority.path(env, old_root: old_root)
			expect(path).to be == File.expand_path("localhost.rb", xdg_state_home)
			expect(File).to be(:exist?, File.expand_path("localhost.crt", path))
			expect(File).to be(:exist?, File.expand_path("localhost.key", path))
			
			expect(File).not.to be(:exist?, old_root)
		end
	end
	
	with '#certificate' do
		it "is not valid for more than 1 year" do
			certificate = authority.certificate
			validity = certificate.not_after - certificate.not_before
			
			# https://support.apple.com/en-us/102028
			expect(validity).to be <= 398 * 24 * 60 * 60
		end
	end
	
	it "have correct key and certificate path" do
		authority.save
		
		expect(File).to be(:exist?, authority.certificate_path)
		expect(File).to be(:exist?, authority.key_path)
		
		expect(File).to be(:exist?, File.expand_path("localhost.lock", @root))
		expect(File).to be(:exist?, File.expand_path("localhost.crt", @root))
		expect(File).to be(:exist?, File.expand_path("localhost.key", @root))
	end
	
	with '#store' do
		it "can verify certificate" do
			expect(authority.store.verify(authority.certificate)).to be == true
		end
	end
	
	with '#server_context' do
		it "can generate appropriate ssl context" do
			expect(authority.server_context).to be_a OpenSSL::SSL::SSLContext
		end
	end
end
