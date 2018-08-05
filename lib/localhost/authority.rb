# Copyright, 2018, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'yaml'
require 'openssl'

module Localhost
	class Authority
		def self.path
			File.expand_path("~/.localhost")
		end
		
		def self.fetch(*args)
			authority = self.new(*args)
			path = self.path
			
			unless authority.load(path)
				Dir.mkdir(path, 0700) unless File.directory?(path)
				
				authority.save(path)
			end
			
			return authority
		end
		
		def initialize(hostname = "localhost")
			@hostname = hostname
			
			@key = nil
			@name = nil
			@certificate = nil
		end
		
		def key
			@key ||= OpenSSL::PKey::RSA.new(1024)
		end
		
		def name
			@name ||= OpenSSL::X509::Name.parse("O=Development/CN=#{@hostname}")
		end
		
		def certificate
			@certificate ||= OpenSSL::X509::Certificate.new.tap do |certificate|
				certificate.subject = self.name
				# We use the same issuer as the subject, which makes this certificate self-signed:
				certificate.issuer = self.name
				
				certificate.public_key = self.key.public_key
				
				certificate.serial = 1
				
				certificate.not_before = Time.now
				certificate.not_after = Time.now + (3600 * 24 * 365 * 10)
				
				extension_factory = OpenSSL::X509::ExtensionFactory.new
				extension_factory.subject_certificate = certificate
				extension_factory.issuer_certificate = certificate
				
				certificate.sign self.key, OpenSSL::Digest::SHA256.new
			end
		end
		
		# The certificate store which is used for validating the server certificate:
		def store
			@store ||= OpenSSL::X509::Store.new.tap do |store|
				store.add_cert(self.certificate)
			end
		end
		
		def ssl_context(*args)
			OpenSSL::SSL::SSLContext.new(*args).tap do |context|
				context.key = self.key
				context.cert = self.certificate
				context.cert_store = self.store
				
				context.session_id_context = "localhost"
				
				context.set_params
			end
		end
		
		def load(path)
			if File.directory? path
				key_path = File.join(path, "#{@hostname}.key")
				return false unless File.exist?(key_path)
				@key = OpenSSL::PKey::RSA.new(File.read(key_path))
				
				certificate_path = File.join(path, "#{@hostname}.crt")
				@certificate = OpenSSL::X509::Certificate.new(File.read(certificate_path))
				
				return true
			end
		end
		
		def save(path)
			File.write(
				File.join(path, "#{@hostname}.crt"),
				self.certificate.to_pem
			)
			
			File.write(
				File.join(path, "#{@hostname}.key"),
				self.key.to_pem
			)
		end
	end
end
