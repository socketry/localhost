# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

module Localhost
	module System
		module Darwin
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