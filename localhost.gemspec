# frozen_string_literal: true

require_relative "lib/localhost/version"

Gem::Specification.new do |spec|
	spec.name = "localhost"
	spec.version = Localhost::VERSION
	
	spec.summary = "Manage a local certificate authority for self-signed localhost development servers."
	spec.authors = ["Samuel Williams", "Olle Jonsson", "Ye Lin Aung", "Akshay Birajdar", "Antonio Terceiro", "Gabriel Sobrinho", "Juri Hahn", "Richard S. Leung", "Yuuji Yaginuma"]
	spec.license = "MIT"
	
	spec.cert_chain  = ['release.cert']
	spec.signing_key = File.expand_path('~/.gem/release.pem')
	
	spec.homepage = "https://github.com/socketry/localhost"
	
	spec.files = Dir.glob(['{lib}/**/*', '*.md'], File::FNM_DOTMATCH, base: __dir__)
	
	spec.required_ruby_version = ">= 3.0"
end
