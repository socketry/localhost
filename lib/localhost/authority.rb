# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.
# Copyright, 2019, by Richard S. Leung.
# Copyright, 2021, by Akshay Birajdar.
# Copyright, 2021, by Ye Lin Aung.
# Copyright, 2023, by Antonio Terceiro.
# Copyright, 2023, by Yuuji Yaginuma.

require 'openssl'

module Localhost
	# Represents a single public/private key pair for a given hostname.
	class Authority
		def self.path
			File.expand_path("~/.localhost")
		end
		
		# List all certificate authorities in the given directory:
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
		
		# Fetch (load or create) a certificate with the given hostname.
		# See {#initialize} for the format of the arguments.
		def self.fetch(*arguments, **options)
			authority = self.new(*arguments, **options)
			
			unless authority.load
				authority.save
			end
			
			return authority
		end
		
		# Create an authority forn the given hostname.
		# @parameter hostname [String] The common name to use for the certificate.
		# @parameter root [String] The root path for loading and saving the certificate.
		def initialize(hostname = "localhost", root: self.class.path)
			@root = root
			@hostname = hostname
			
			@key = nil
			@name = nil
			@certificate = nil
			@store = nil
		end
		
		# The hostname of the certificate authority.
		attr :hostname
		
		BITS = 1024*2
		
		def ecdh_key
			@ecdh_key ||= OpenSSL::PKey::EC.new "prime256v1"
		end
		
		def dh_key
			@dh_key ||= OpenSSL::PKey::DH.new(BITS)
		end
		
		# The private key path.
		def key_path
			File.join(@root, "#{@hostname}.key")
		end
		
		# The public certificate path.
		def certificate_path
			File.join(@root, "#{@hostname}.crt")
		end
		
		# The private key.
		def key
			@key ||= OpenSSL::PKey::RSA.new(BITS)
		end
		
		def key= key
			@key = key
		end
		
		# The certificate name.
		def name
			@name ||= OpenSSL::X509::Name.parse("/O=Development/CN=#{@hostname}")
		end
		
		def name= name
			@name = name
		end
		
		# The public certificate.
		# @returns [OpenSSL::X509::Certificate] A self-signed certificate.
		def certificate
			@certificate ||= OpenSSL::X509::Certificate.new.tap do |certificate|
				certificate.subject = self.name
				# We use the same issuer as the subject, which makes this certificate self-signed:
				certificate.issuer = self.name
				
				certificate.public_key = self.key.public_key
				
				certificate.serial = Time.now.to_i
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
		
		# The certificate store which is used for validating the server certificate.
		def store
			@store ||= OpenSSL::X509::Store.new.tap do |store|
				store.add_cert(self.certificate)
			end
		end
		
		SERVER_CIPHERS = "EECDH+CHACHA20:EECDH+AES128:RSA+AES128:EECDH+AES256:RSA+AES256:EECDH+3DES:RSA+3DES:!MD5".freeze
		
		# @returns [OpenSSL::SSL::SSLContext] An context suitable for implementing a secure server.
		def server_context(*arguments)
			OpenSSL::SSL::SSLContext.new(*arguments).tap do |context|
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
		
		# @returns [OpenSSL::SSL::SSLContext] An context suitable for connecting to a secure server using this authority.
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
