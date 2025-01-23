require_relative "src/downloader"
require_relative "src/importer_manager"

# Stop annoying warning
# See https://github.com/jnunemaker/httparty/issues/568
HTTParty::Response.class_eval do
  def warn_about_nil_deprecation
  end
end

Downloader.new.start
ImporterManager.new.start
