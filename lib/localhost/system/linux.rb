# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "etc"

module Localhost
	module System
		module Darwin
			def self.install(certificate)
				filename = File.basename(certificate)
				destination = "/usr/local/share/ca-certificates/localhost-#{filename}"
				
				system("sudo", "cp", certificate, destination)
				system("sudo", "update-ca-certificates")
			end
		end
	end
end