# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

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
		
		# Initialize the issuer with the given name.
		# 
		# @parameter name [String] The common name to use for the certificate.
		# @parameter path [String] The path path for loading and saving the certificate.
		def initialize(name = "development", path: State.path)
			@name = name
			@path = path
			
			@subject = nil
			@key = nil
			@certificate = nil
		end
		
		# @returns [String] The path to the private key.
		def key_path
			File.join(@path, "#{@name}.key")
		end
		
		# @returns [String] The path to the public certificate.
		def certificate_path
			File.join(@path, "#{@name}.crt")
		end
		
		# @returns [OpenSSL::X509::Name] The subject name for the certificate.
		def subject
			@subject ||= OpenSSL::X509::Name.parse("/O=localhost.rb/CN=#{@name}")
		end
		
		# Set the subject name for the certificate.
		#
		# @parameter subject [OpenSSL::X509::Name] The subject name for the certificate.
		def subject= subject
			@subject = subject
		end
		
		# @returns [OpenSSL::PKey::RSA] The private key.
		def key
			@key ||= OpenSSL::PKey::RSA.new(BITS)
		end
		
		# The public certificate.
		#
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
				certificate.not_after = Time.now + VALIDITY
				
				extension_factory = ::OpenSSL::X509::ExtensionFactory.new
				extension_factory.subject_certificate = certificate
				extension_factory.issuer_certificate = certificate
				
				certificate.add_extension extension_factory.create_extension("basicConstraints", "CA:TRUE", true)
				certificate.add_extension extension_factory.create_extension("keyUsage", "keyCertSign, cRLSign", true)
				certificate.add_extension extension_factory.create_extension("subjectKeyIdentifier", "hash")
				certificate.add_extension extension_factory.create_extension("authorityKeyIdentifier", "keyid:always", false)
				
				certificate.sign self.key, OpenSSL::Digest::SHA256.new
			end
		end
		
		# Load the certificate and key from the given path.
		#
		# @parameter path [String] The path to load the certificate and key.
		# @returns [Boolean] True if the certificate and key were loaded successfully.
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
		
		# @returns [String] The path to the lockfile.
		def lockfile_path
			File.join(@path, "#{@name}.lock")
		end
		
		# Save the certificate and key to the given path.
		#
		# @parameter path [String] The path to save the certificate and key.
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
			
			return true
		end
	end
end
