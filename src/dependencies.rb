# require "open-uri"
require "fileutils"
require "zip"
require "csv"
require "httparty"
require "nokogiri"
require "tty-prompt"
require "pg"
require "sequel"
require "benchmark"
require "yaml"
require "rainbow/refinement"
require "ruby-progressbar"
require "down"

require_relative "importer_manager"
require_relative "downloader"

# Stop annoying warning
# See https://github.com/jnunemaker/httparty/issues/568
HTTParty::Response.class_eval do
  def warn_about_nil_deprecation
  end
end
