#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.
# Copyright, 2021, by Ye Lin Aung.

# Require the required libraries:
require "async"
require "async/io/host_endpoint"
require "async/io/ssl_endpoint"
require "async/http/server"
require "async/http/client"
require "localhost"

# The (self-signed) authority to use:
hostname = "localhost"
authority = Localhost::Authority.fetch(hostname)

# The server app:
app = lambda do |request|
	Protocol::HTTP::Response[200, {}, ["Hello World"]]
end

# Bind to the specified host:
endpoint = Async::IO::Endpoint.tcp(hostname, "8080")

# Prepare the server, endpoint will be used for `bind`:
server_endpoint = Async::IO::SSLEndpoint.new(endpoint, ssl_context: authority.server_context)
server = Async::HTTP::Server.new(app, server_endpoint, protocol: Async::HTTP::Protocol::HTTP1, scheme: "https")

# Prepare the client, endpoint will be used for `connect`:
client_endpoint = Async::IO::SSLEndpoint.new(endpoint, ssl_context: authority.client_context)
client = Async::HTTP::Client.new(client_endpoint, protocol: Async::HTTP::Protocol::HTTP1, scheme: "https", authority: authority)

# Run the reactor:
Async do |task|
	# Start the server task:
	server_task = task.async do
		server.run
	end
	
	# Connect to the server:
	response = client.get("/")
	puts "Status: #{response.status}\n#{response.read}"
	
	# Stop the server:
	server_task.stop
end
