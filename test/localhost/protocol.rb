# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2024, by Samuel Williams.

require 'localhost/authority'

require 'sus/fixtures/async/http/server_context'

require 'async/process'
require 'fileutils'

AValidProtocol = Sus::Shared("valid protocol") do |protocol, openssl_options, curl_options|
	it "can connect using #{protocol} using openssl" do
		uri = URI.parse(bound_url)
		
		status = Async::Process.spawn("openssl", "s_client", "-connect", "#{uri.host}:#{uri.port}", *openssl_options)
		
		expect(status).to be(:success?)
	end
	
	it "can connect using HTTP over #{protocol} using curl" do
		status = Async::Process.spawn("curl", "--verbose", "--insecure", bound_url, *curl_options)
		
		expect(status).to be(:success?)
	end
end

describe Localhost::Authority do
	# We test the actual authority:
	let(:authority) {subject.new}
	
	include Sus::Fixtures::Async::HTTP::ServerContext
	
	def url
		"https://localhost:0"
	end
	
	def make_server_endpoint(bound_endpoint)
		Async::IO::SSLEndpoint.new(super, ssl_context: authority.server_context)
	end
	
	def make_client_endpoint(bound_endpoint)
		Async::IO::SSLEndpoint.new(super, ssl_context: authority.client_context)
	end
	
	# Curl no longer supports this.
	# it_behaves_like "invalid protocol", "SSLv3", ["-ssl3"], ["--sslv3"]
	
	# Most modern browsers have removed support for these:
	# it_behaves_like "valid protocol", "TLSv1", ["-tls1"], ["--tlsv1"]
	# it_behaves_like "valid protocol", "TLSv1.1", ["-tls1_1"], ["--tlsv1.1"]
	
	it_behaves_like AValidProtocol, "default", [], []
	it_behaves_like AValidProtocol, "TLSv1.2", ["-tls1_2"], ["--tlsv1.2"]
	it_behaves_like AValidProtocol, "TLSv1.3", ["-tls1_3"], ["--tlsv1.3"]
	
	it "can connect using HTTPS" do
		response = client.get("/")
		
		expect(response).to be(:success?)
	ensure
		response&.finish
		client.close
	end
end
