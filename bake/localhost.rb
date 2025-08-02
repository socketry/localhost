# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2025, by Samuel Williams.

def initialize(...)
	super
	
	require_relative "../lib/localhost"
end

# List all local authorities.
#
# @returns [Array(Hash)] The certificate and key paths, and the expiry date.
def list
	Localhost::Authority.list.map(&:to_h)
end

# Fetch a local authority by hostname. If the authority does not exist, it will be created.
#
# @parameter hostname [String] The hostname to fetch.
# @returns [Hash] The certificate and key paths, and the expiry date.
def fetch(hostname)
	Localhost::Authority.fetch(hostname)
end

# Install a certificate into the system trust store.
# @parameter name [String] The name of the issuer to install, or nil for the default issuer.
def install(name: nil)
	issuer = Localhost::Issuer.fetch(name)
	
	$stderr.puts "Installing certificate for #{issuer.subject}..."
	Localhost::System.current.install(issuer.certificate_path)
	
	return nil
end

# Delete all local authorities.
def purge
	$stderr.puts "Purging localhost state..."
	
	Localhost::State.purge
	
	return nil
end
