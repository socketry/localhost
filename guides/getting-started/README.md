# Getting Started

This guide explains how to use `localhost` for provisioning local TLS certificates for development.

## Installation

Add the gem to your project:

~~~ bash
$ bundle add localhost
~~~

## Core Concepts

`localhost` has one core concept:

- A {ruby Localhost::Authority} instance which represents a public and private key pair that can be used for both clients and servers.

### Files

The certificate and private key are stored in `~/.localhost/`. You can delete them and they will be regenerated. If you added the certificate to your computer's certificate store/keychain, you'll you'd need to update it.

## Usage

In general, you won't need to do anything at all. The application server you are using will automatically provision a self-signed certificate for localhost. That being said, if you want to implement your own self-signed secure server, the following example demonstrates how to use the {ruby Localhost::Authority}:

``` ruby
require 'socket'
require 'thread'

require 'localhost/authority'

# Get the self-signed authority for localhost:
authority = Localhost::Authority.fetch

ready = Thread::Queue.new

# Start a server thread:
server_thread = Thread.new do
	server = OpenSSL::SSL::SSLServer.new(TCPServer.new("localhost", 4050), authority.server_context)
	
	server.listen
	
	ready << true
	
	peer = server.accept
	
	peer.puts "Hello World!"
	peer.flush
	
	peer.close
end

ready.pop

client = OpenSSL::SSL::SSLSocket.new(TCPSocket.new("localhost", 4050), authority.client_context)

# Initialize SSL connection:
client.connect

# Read the encrypted message:
puts client.read(12)

client.close
server_thread.join
```
