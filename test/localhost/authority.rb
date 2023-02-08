# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023, by Samuel Williams.

require 'localhost/authority'

require 'sus/fixtures/async/reactor_context'
require 'async/io/host_endpoint'
require 'async/io/ssl_endpoint'
require 'async/io/shared_endpoint'

require 'async/process'
require 'fileutils'

describe Localhost::Authority do
	let(:authority) {subject.new}
	
	it "can generate key and certificate" do
		FileUtils.mkdir_p("ssl")
		authority.save("ssl")
		
		expect(File).to be(:exist?, "ssl/localhost.lock")
		expect(File).to be(:exist?, "ssl/localhost.crt")
		expect(File).to be(:exist?, "ssl/localhost.key")
	end
	
	it "have correct key and certificate path" do
		authority.save(authority.class.path)
		expect(File).to be(:exist?, authority.certificate_path)
		expect(File).to be(:exist?, authority.key_path)

		expect(authority.key_path).to be == File.join(File.expand_path("~/.localhost"), "localhost.key")
		expect(authority.certificate_path).to be == File.join(File.expand_path("~/.localhost"), "localhost.crt")
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
	
	with 'client/server' do
		include Sus::Fixtures::Async::ReactorContext
		
		let(:endpoint) {Async::IO::Endpoint.tcp("localhost", 4040)}
		let(:server_endpoint) {Async::IO::SSLEndpoint.new(endpoint, ssl_context: authority.server_context)}
		let(:client_endpoint) {Async::IO::SSLEndpoint.new(endpoint, ssl_context: authority.client_context)}
		
		let(:client) {client_endpoint.connect}
		
		def before
			@bound_endpoint = Async::IO::SharedEndpoint.bound(server_endpoint)
			
			@server_task = reactor.async do
				@bound_endpoint.accept do |peer|
					peer.write("Hello World!")
					peer.close
				end
			end
			
			super
		end
		
		def after
			@server_task&.stop
			@bound_endpoint&.close
			
			super
		end
		
		it "can verify peer" do
			expect(client.read(12)).to be == "Hello World!"
			
			client.close
		end
	end
end
