require "digest"
require "fileutils"

class Transcoder

  CONCURRENCY = 8.freeze
  DEFAULT_OUTPUT_DIR = File.join(File.dirname(__FILE__), "..", "mp3s").freeze

  # @param output [String] path to the directory to store output MP3s
  def initialize(target: DEFAULT_OUTPUT_DIR)
    @flacs = Dir["**/*.flac"]
    @mp3s  = Dir["**/*.mp3"]
    @existing = Dir["#{ target }/*.mp3"]
    @target = target
    FileUtils.mkdir_p(@target)
  end

  def transcode
    @flacs.each do |f|
      target = dest(f)
      next if @existing.include?(target) || File.exist?(target)
      puts "Transcoding #{ f} -> #{ target }"
      `ffmpeg -loglevel panic -i "#{ f }" -threads #{ CONCURRENCY } -acodec libmp3lame -b:a 320k '#{ dest(f) }'`
    end

    @mp3s.each do |f|
      target = dest(f)
      puts "Copying #{ f } -> #{ target }"
      FileUtils.cp(f, target)
    end
  end

  private

  def dest(file)
    "#{ @target }/#{ hashify(file) }.mp3"
  end

  def hashify(file)
    Digest::SHA256.hexdigest(File.read(file)).upcase
  end
end

Transcoder.new.transcode
