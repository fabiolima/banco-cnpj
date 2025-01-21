require "yaml"
require "./src/downloader"
require_relative "src/importer_manager"

HTTParty::Response.class_eval do
  def warn_about_nil_deprecation
  end
end

# download_config = YAML.load_file('./src/config/download.yaml').transform_keys!(&:to_sym)

# Downloader.new.start

ImporterManager.new.start
