require "rainbow/refinement"
require "tty-prompt"
require_relative "scraper/scraping_manager"

using Rainbow

class Downloader
  def initialize
    @prompt = TTY::Prompt.new
    @scraping_manager = ScrapingManager.new
  end

  def start
    version = choose_version
    files = version.files

    return unless @prompt.yes?("#{files.map { |f| f.filename }.join("\n")} \n #{files.size} arquivos encontrados. Deseja começar o download?")

    files.each do |f|
      f.download
      puts "\n"
    end
  end

  private

  def choose_version
    available_versions = @scraping_manager.available_versions

    version_name = @prompt.select("Selecione a versão desejada", available_versions.map(&:name), per_page: 10)

    available_versions.find { |v| v.name == version_name }
  end
end
