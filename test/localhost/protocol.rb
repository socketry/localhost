# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2025, by Samuel Williams.

require "localhost/authority"

require "sus/fixtures/async/http/server_context"
require "io/endpoint/ssl_endpoint"
require "fileutils"

AValidProtocol = Sus::Shared("valid protocol") do |protocol, openssl_options, curl_options|
	it "can connect using #{protocol} using openssl" do
		uri = URI.parse(bound_url)
		
		status = system("openssl", "s_client", "-connect", "#{uri.host}:#{uri.port}", *openssl_options, in: IO::NULL)
		
		expect(status).to be == true
	end
	
	it "can connect using HTTP over #{protocol} using curl" do
		skip_if_ruby_platform("darwin") # curl on macOS does not support --tlsv1.3
		
		status = system("curl", "--verbose", "--insecure", bound_url, *curl_options)
		
		expect(status).to be == true
	end
end

describe Localhost::Authority do
	# We test the actual authority:
	let(:authority) {subject.new}
	
	include Sus::Fixtures::Async::HTTP::ServerContext
	
	def url
		"https://localhost:0"
	end
	
	def timeout
		nil
	end
	
	def endpoint_options
		super.merge(
			ssl_context: authority.server_context
		)
	end
	
	def make_client_endpoint(bound_endpoint)
		IO::Endpoint::SSLEndpoint.new(super, ssl_context: authority.client_context)
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
