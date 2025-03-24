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
	Localhost::Authority.list.map do |authority|
		{
			certificate_path: authority.certificate_path,
			key_path: authority.key_path,
			expires_at: authority.certificate.not_after,
		}
	end
end

# Fetch a local authority by hostname. If the authority does not exist, it will be created.
#
# @parameter hostname [String] The hostname to fetch.
# @returns [Hash] The certificate and key paths, and the expiry date.
def fetch(hostname)
	if authority = Localhost::Authority.fetch(hostname)
		return {
			certificate_path: authority.certificate_path,
			key_path: authority.key_path,
			expires_at: authority.certificate.not_after,
		}
	end
end

def purge
	Localhost::State.purge
end
