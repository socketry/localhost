# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2023, by Samuel Williams.

# List all local authorities.
def list
	require_relative '../lib/localhost'
	
	terminal = self.terminal
	
	Localhost::Authority.list do |authority|
		terminal.print(
			:hostname, authority.hostname, " ",
			:name, authority.name, "\n", :reset,
			"\tCertificate Path: ", authority.certificate_path, "\n",
			"\t        Key Path: ", authority.key_path, "\n",
			"\t         Expires: ", authority.certificate.not_after, "\n",
			:reset, "\n"
		)
	end
end

private

def terminal(out = $stdout)
	require 'console/terminal'
	
	terminal = Console::Terminal.for(out)
	
	terminal[:hostname] = terminal.style(nil, nil, :bold)
	terminal[:name] = terminal.style(:blue)
	
	return terminal
end
