# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

module Localhost
	module System
		# Darwin specific system operations.
		module Darwin
			# Install a certificate into the system trust store.
			#
			# @parameter certificate [String] The path to the certificate file.
			def self.install(certificate)
				login_keychain = File.expand_path("~/Library/Keychains/login.keychain-db")
				
				system(
					"security", "add-trusted-cert",
					"-d", "-r", "trustRoot",
					"-k", login_keychain,
					certificate
				)
			end
		end
	end
end