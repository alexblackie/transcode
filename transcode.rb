# vim: ts=4 sw=4 noexpandtab
require "digest"
require "fileutils"

class Transcoder

	CONCURRENCY = 8.freeze
	DEFAULT_OUTPUT_DIR = File.join(File.dirname(__FILE__), "..", "mp3s").freeze
	MANIFEST_FILE = ".transcode.manifest".freeze
	MANIFEST_DELIMITER = "||".freeze

	# @param output [String] path to the directory to store output MP3s
	def initialize(target: DEFAULT_OUTPUT_DIR)
		@masters = Dir["**/*.{flac,m4a}"]
		@mp3s  = Dir["**/*.mp3"]
		@existing = Dir["#{ target }/*.mp3"]
		@target = target
		@manifest = populate_manifest()
		FileUtils.mkdir_p(@target)
	end

	def transcode
		@masters.each do |f|
			next if @manifest.has_key?(f)
			target = dest(f)
			puts "Transcoding #{ f} -> #{ target }"
			unless File.exist?(target)
				`ffmpeg -loglevel panic -i "#{ f }" -threads #{ CONCURRENCY } -acodec libmp3lame -qscale:a 0 '#{ dest(f) }'`
			end
			@manifest[f] = target
		end

		@mp3s.each do |f|
			next if @manifest.has_key?(f)
			target = dest(f)
			puts "Copying #{ f } -> #{ target }"
			unless File.exist?(target)
				FileUtils.cp(f, target)
			end
			@manifest[f] = target
		end

		write_manifest()
	end

	private

	def dest(file)
		"#{ @target }/#{ hashify(file) }.mp3"
	end

	def hashify(file)
		Digest::SHA256.hexdigest(File.read(file)).upcase
	end

	def write_manifest
		content = @manifest.reduce(""){|acc, (orig,dest)| acc + orig + MANIFEST_DELIMITER + dest + "\n"}
		File.write(MANIFEST_FILE, content)
	end

	def populate_manifest
		FileUtils.touch(MANIFEST_FILE) unless File.exist?(MANIFEST_FILE)
		File.
			read(MANIFEST_FILE).
			lines.
			reduce({}) do |acc, l|
				line = l.split(MANIFEST_DELIMITER)
				acc[line.first] = line.last
				acc
			end
	end
end

Transcoder.new.transcode
