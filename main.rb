require "yaml"
require "./src/downloader"

download_config = YAML.load_file('./src/config/download.yaml').transform_keys!(&:to_sym)
Downloader.new(**download_config).start

# ImporterManager.new.start
