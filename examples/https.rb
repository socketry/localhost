#!/usr/bin/env ruby

require 'async'
require 'async/io/host_endpoint'
require 'async/io/ssl_endpoint'
require 'async/http/server'
require 'async/http/client'
require 'localhost/authority'

hostname = "localhost"
authority = Localhost::Authority.fetch(hostname)

app = lambda do |request|
	Async::HTTP::Response[200, {}, ["Hello World!"]]
end

endpoint = Async::IO::Endpoint.tcp(hostname, "8080")

server_endpoint = Async::IO::SSLEndpoint.new(endpoint, ssl_context: authority.server_context)
server = Async::HTTP::Server.new(app, server_endpoint, Async::HTTP::Protocol::HTTP1)

client_endpoint = Async::IO::SSLEndpoint.new(endpoint, ssl_context: authority.client_context)
client = Async::HTTP::Client.new(client_endpoint, Async::HTTP::Protocol::HTTP1)

Async::Reactor.run do |task|
	server_task = task.async do
		server.run
	end
	
	response = client.get("/")
	puts "Status: #{response.status}\n#{response.read}"
	
	server_task.stop
end
