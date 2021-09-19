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
		
		def self.list(root = self.path)
			return to_enum(:list) unless block_given?
			
			Dir.glob("*.crt", base: root) do |path|
				name = File.basename(path, ".crt")
				
				authority = self.new(name, root: root)
				
				if authority.load
					yield authority
				end
			end
		end
		
		def self.fetch(*arguments, **options)
			authority = self.new(*arguments, **options)
			
			unless authority.load
				authority.save
			end
			
			return authority
		end
		
		def initialize(hostname = "localhost", root: self.class.path)
			@root = root
			@hostname = hostname
			
			@key = nil
			@name = nil
			@certificate = nil
			@store = nil
		end
		
		attr :hostname
		
		BITS = 1024*2
		
		def ecdh_key
			@ecdh_key ||= OpenSSL::PKey::EC.new "prime256v1"
		end
		
		def dh_key
			@dh_key ||= OpenSSL::PKey::DH.new(BITS)
		end
		
		def key_path
			File.join(@root, "#{@hostname}.key")
		end
		
		def certificate_path
			File.join(@root, "#{@hostname}.crt")
		end
		
		def key
			@key ||= OpenSSL::PKey::RSA.new(BITS)
		end
		
		def key= key
			@key = key
		end
		
		def name
			@name ||= OpenSSL::X509::Name.parse("/O=Development/CN=#{@hostname}")
		end
		
		def name= name
			@name = name
		end
		
		def certificate
			@certificate ||= OpenSSL::X509::Certificate.new.tap do |certificate|
				certificate.subject = self.name
				# We use the same issuer as the subject, which makes this certificate self-signed:
				certificate.issuer = self.name
				
				certificate.public_key = self.key.public_key
				
				certificate.serial = 1
				certificate.version = 2
				
				certificate.not_before = Time.now
				certificate.not_after = Time.now + (3600 * 24 * 365 * 10)
				
				extension_factory = OpenSSL::X509::ExtensionFactory.new
				extension_factory.subject_certificate = certificate
				extension_factory.issuer_certificate = certificate
				
				certificate.extensions = [
					extension_factory.create_extension("basicConstraints", "CA:FALSE", true),
					extension_factory.create_extension("subjectKeyIdentifier", "hash"),
				]
				
				certificate.add_extension extension_factory.create_extension("authorityKeyIdentifier", "keyid:always,issuer:always")
				certificate.add_extension extension_factory.create_extension("subjectAltName", "DNS: #{@hostname}")
				
				certificate.sign self.key, OpenSSL::Digest::SHA256.new
			end
		end
		
		# The certificate store which is used for validating the server certificate:
		def store
			@store ||= OpenSSL::X509::Store.new.tap do |store|
				store.add_cert(self.certificate)
			end
		end
		
		SERVER_CIPHERS = "EECDH+CHACHA20:EECDH+AES128:RSA+AES128:EECDH+AES256:RSA+AES256:EECDH+3DES:RSA+3DES:!MD5".freeze
		
		def server_context(*args)
			OpenSSL::SSL::SSLContext.new(*args).tap do |context|
				context.key = self.key
				context.cert = self.certificate
				
				context.session_id_context = "localhost"
				
				if context.respond_to? :tmp_dh_callback=
					context.tmp_dh_callback = proc {self.dh_key}
				end
				
				if context.respond_to? :ecdh_curves=
					context.ecdh_curves = 'P-256:P-384:P-521'
				elsif context.respond_to? :tmp_ecdh_callback=
					context.tmp_ecdh_callback = proc {self.ecdh_key}
				end
				
				context.set_params(
					ciphers: SERVER_CIPHERS,
					verify_mode: OpenSSL::SSL::VERIFY_NONE,
				)
			end
		end
		
		def client_context(*args)
			OpenSSL::SSL::SSLContext.new(*args).tap do |context|
				context.cert_store = self.store
				
				context.set_params(
					verify_mode: OpenSSL::SSL::VERIFY_PEER,
				)
			end
		end
		
		def load(path = @root)
			if File.directory?(path)
				certificate_path = File.join(path, "#{@hostname}.crt")
				key_path = File.join(path, "#{@hostname}.key")
				
				return false unless File.exist?(certificate_path) and File.exist?(key_path)
				
				certificate = OpenSSL::X509::Certificate.new(File.read(certificate_path))
				key = OpenSSL::PKey::RSA.new(File.read(key_path))
				
				# Certificates with old version need to be regenerated.
				return false if certificate.version < 2
				
				@certificate = certificate
				@key = key
				
				return true
			end
		end
		
		def save(path = @root)
			Dir.mkdir(path, 0700) unless File.directory?(path)
			
			lockfile_path = File.join(path, "#{@hostname}.lock")
			
			File.open(lockfile_path, File::RDWR|File::CREAT, 0644) do |lockfile|
				lockfile.flock(File::LOCK_EX)
				
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
end
