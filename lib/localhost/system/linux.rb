# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

module Localhost
	module System
		# Linux specific system operations.
		module Linux
			# Install a certificate into the system trust store.
			#
			# @parameter certificate [String] The path to the certificate file.
			def self.install(certificate)
				filename = File.basename(certificate)
				destination = "/usr/local/share/ca-certificates/localhost-#{filename}"
				
				system("sudo", "cp", certificate, destination)
				system("sudo", "update-ca-certificates")
			end
		end
	end
end