# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2023, by Samuel Williams.

def initialize(...)
	super
	
	require_relative "../lib/localhost"
end

# List all local authorities.
def list
	Localhost::Authority.list.map do |authority|
		{
			certificate_path: authority.certificate_path,
			key_path: authority.key_path,
			expires_at: authority.certificate.not_after,
		}
	end
end

def fetch(hostname)
	if authority = Localhost::Authority.fetch(hostname)
		return {
			certificate_path: authority.certificate_path,
			key_path: authority.key_path,
			expires_at: authority.certificate.not_after,
		}
	end
end
