# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

module Localhost
	# @namespace
	module System
		# @return [Class] The  best system class for the current platform.
		def self.current
			case RUBY_PLATFORM
			when /darwin/
				require "localhost/system/darwin"
				Darwin
			when /linux/
				require "localhost/system/linux"
				Linux
			else
				raise NotImplementedError, "Unsupported platform: #{RUBY_PLATFORM}"
			end
		end
	end
end
