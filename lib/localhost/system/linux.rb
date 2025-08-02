# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

module Localhost
	module System
		# Linux specific system operations.
		module Linux
			# This appears to be the standard path for the system trust store on many Linux distributions.
			ANCHORS_PATH = "/etc/ca-certificates/trust-source/anchors/"
			UPDATE_CA_TRUST = "update-ca-trust"
			
			# This is an older method for systems that do not use `update-ca-trust`.
			LOCAL_CERTIFICATES_PATH = "/usr/local/share/ca-certificates/"
			UPDATE_CA_CERTIFICATES = "update-ca-certificates"
			
			# Install a certificate into the system trust store.
			#
			# @parameter certificate [String] The path to the certificate file.
			def self.install(certificate)
				filename = File.basename(certificate)
				command = nil
				
				if File.exist?(ANCHORS_PATH)
					# For systems using `update-ca-trust`.
					destination = File.join(ANCHORS_PATH, filename)
					command = UPDATE_CA_TRUST
				elsif File.exist?(LOCAL_CERTIFICATES_PATH)
					# For systems using `update-ca-certificates`.
					destination = File.join(LOCAL_CERTIFICATES_PATH, filename)
					command = UPDATE_CA_CERTIFICATES
				else
					raise "No known system trust store found. Please install the certificate manually."
				end
				
				success = system("sudo", "cp", certificate, destination)
				success &= system("sudo", command)
				
				if success
					$stderr.puts "Installed certificate to #{destination}"
					
					return true
				else
					raise "Failed to install certificate: #{certificate}"
				end
			end
		end
	end
end
