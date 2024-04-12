# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023, by Samuel Williams.

require 'covered/sus'
include Covered::Sus

require 'fileutils'
FileUtils.mkdir_p(::File.expand_path(ENV['XDG_STATE_HOME'] || "~/.local/state"))
