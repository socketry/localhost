# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "fileutils"

module Localhost
	# Represents a single public/private key pair for a given hostname.
	module State
		# Where to store the key pair on the filesystem. This is a subdirectory
		# of $XDG_STATE_HOME, or ~/.local/state/ when that's not defined.
		#
		# Ensures that the directory to store the certificate exists. If the legacy
		# directory (~/.localhost/) exists, it is moved into the new XDG Basedir
		# compliant directory.
		#
		# @parameter env [Hash] The environment to use for configuration.
		def self.path(env = ENV)
			path = File.expand_path("localhost.rb", env.fetch("XDG_STATE_HOME", "~/.local/state"))
			
			unless File.directory?(path)
				FileUtils.mkdir_p(path, mode: 0700)
			end
			
			return path
		end
		
		# Delete the directory where the key pair is stored.
		#
		# @parameter env [Hash] The environment to use for configuration.
		def self.purge(env = ENV)
			path = self.path(env)
			
			FileUtils.rm_rf(path)
		end	
	end
end
