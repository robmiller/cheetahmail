require "bundler/setup"

require "nokogiri"
require "mechanize"

module CheetahMail
  AGENT = Mechanize.new
  AGENT.user_agent_alias = "Mac Safari"

  class NotAuthorised < StandardError; end

  class << self
    def logged_in?
      @logged_in
    end

    def logged_in=(logged_in)
      @logged_in = logged_in
    end

    def output_dir
      (Pathname(__dir__) + ".." + "output").realpath
    end

    def log(message)
      $stderr.puts message
    end
  end
end

require_relative "cheetahmail/login"
require_relative "cheetahmail/segmentation"
