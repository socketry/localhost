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

AValidProtocol = Sus::Shared("valid protocol") do |protocol, openssl_options, curl_options|
	it "can connect using #{protocol} using openssl" do
		status = Async::Process.spawn("openssl", "s_client", "-connect", "localhost:4040", *openssl_options)
		
		expect(status).to be(:success?)
	end
	
	it "can connect using HTTP over #{protocol} using curl" do
		status = Async::Process.spawn("curl", "--verbose", "--insecure", "https://localhost:4040", *curl_options)
		
		expect(status).to be(:success?)
	end
end

AnInvalidProtocol = Sus::Shared("invalid protocol") do |protocol, openssl_options, curl_options|
	it "can't connect using #{protocol}" do
		status = Async::Process.spawn("openssl", "s_client", "-connect", "localhost:4040", *openssl_options)
		
		expect(status).to_not be(:success?)
	end
	
	it "can't connect using HTTP over #{protocol}" do
		status = Async::Process.spawn("curl", "--verbose", "--insecure", "https://localhost:4040", *curl_options)
		
		expect(status).to_not be(:success?)
	end
end

describe Localhost::Authority do
	let(:authority) {subject.new}
	
	include Sus::Fixtures::Async::ReactorContext
	
	let(:endpoint) {Async::IO::Endpoint.tcp("localhost", 4040)}
	let(:server_endpoint) {Async::IO::SSLEndpoint.new(endpoint, ssl_context: authority.server_context)}
	let(:client_endpoint) {Async::IO::SSLEndpoint.new(endpoint, ssl_context: authority.client_context)}
	
	let(:client) {client_endpoint.connect}
	
	def before
		@bound_endpoint = Async::IO::SharedEndpoint.bound(server_endpoint)
		
		@server_task = reactor.async do
			@bound_endpoint.accept do |peer|
				peer.write("HTTP/1.1 200 Okay\r\n")
				peer.write("Connection: close\r\nContent-Length: 0\r\n\r\n")
				sleep 0.2
				peer.flush
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
	
	# Curl no longer supports this.
	# it_behaves_like "invalid protocol", "SSLv3", ["-ssl3"], ["--sslv3"]
	
	# Most modern browsers have removed support for these:
	# it_behaves_like "valid protocol", "TLSv1", ["-tls1"], ["--tlsv1"]
	# it_behaves_like "valid protocol", "TLSv1.1", ["-tls1_1"], ["--tlsv1.1"]
	
	it_behaves_like AValidProtocol, "TLSv1.2", ["-tls1_2"], ["--tlsv1.2"]
	it_behaves_like AValidProtocol, "default", [], []
end
