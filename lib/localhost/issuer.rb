# frozen_string_literal: true

require "openssl"
require "fileutils"

require_relative "state"

module Localhost
	# Represents a local Root Certificate Authority used to sign development certificates.
	class Issuer
		# The default number of bits for the private key. 4096 bits.
		BITS = 4096
		
		# The default validity period for the certificate. 10 years in seconds.
		VALIDITY = 10 * 365 * 24 * 60 * 60
		
		# Fetch (load or create) a certificate issuer with the given name.
		# See {#initialize} for the format of the arguments.
		def self.fetch(*arguments, **options)
			issuer = self.new(*arguments, **options)
			
			unless issuer.load
				issuer.save
			end
			
			return issuer
		end
		
		def initialize(name = "development", path: State.path, bits: BITS, validity: VALIDITY)
			@name = name
			@path = path
			
			@bits = bits
			@validity = validity
			
			@subject = nil
			@key = nil
			@certificate = nil
		end
		
		# The private key path.
		def key_path
			File.join(@path, "#{@name}.key")
		end
		
		# The public certificate path.
		def certificate_path
			File.join(@path, "#{@name}.crt")
		end
		
		# The certificate subject (name).
		def subject
			@subject ||= OpenSSL::X509::Name.parse("/O=localhost.rb/CN=#{@name}")
		end
		
		def subject= subject
			@subject = subject
		end
		
		# The private key.
		def key
			@key ||= OpenSSL::PKey::RSA.new(BITS)
		end
		
		# The public certificate.
		# @returns [OpenSSL::X509::Certificate] A self-signed certificate.
		def certificate
			@certificate ||= OpenSSL::X509::Certificate.new.tap do |certificate|
				certificate.subject = self.subject
				# We use the same issuer as the subject, which makes this certificate self-signed:
				certificate.issuer = self.subject
				
				certificate.public_key = self.key.public_key
				
				certificate.serial = Time.now.to_i
				certificate.version = 2
				
				certificate.not_before = Time.now - 10
				certificate.not_after = Time.now + @validity
				
				extension_factory = ::OpenSSL::X509::ExtensionFactory.new
				extension_factory.subject_certificate = certificate
				
				certificate.add_extension extension_factory.create_extension("basicConstraints", "CA:TRUE", true)
				certificate.add_extension extension_factory.create_extension("keyUsage", "keyCertSign, cRLSign", true)
				certificate.add_extension extension_factory.create_extension("subjectKeyIdentifier", "hash")
				certificate.add_extension extension_factory.create_extension("authorityKeyIdentifier", "keyid:always", false)
				
				certificate.sign self.key, OpenSSL::Digest::SHA256.new
			end
		end
		
		def load(path = @root)
			certificate_path = self.certificate_path
			key_path = self.key_path
			
			return false unless File.exist?(certificate_path) and File.exist?(key_path)
			
			certificate = OpenSSL::X509::Certificate.new(File.read(certificate_path))
			key = OpenSSL::PKey::RSA.new(File.read(key_path))
			
			@certificate = certificate
			@key = key
			
			return true
		end
		
		def lockfile_path
			File.join(@path, "#{@name}.lock")
		end
		
		def save(path = @root)
			lockfile_path = self.lockfile_path
			
			File.open(lockfile_path, File::RDWR|File::CREAT, 0644) do |lockfile|
				lockfile.flock(File::LOCK_EX)
				
				File.write(
					self.certificate_path,
					self.certificate.to_pem
				)
				
				File.write(
					self.key_path,
					self.key.to_pem
				)
			end
		end
	end
end
