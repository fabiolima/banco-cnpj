require "yaml"
require "httparty"
require "nokogiri"
require "retryable"

require_relative "version"

class ScrapingManager
  def initialize
    @config = YAML.load_file("./src/config/download.yaml").transform_keys!(&:to_sym)
  end

  def available_versions
    founded_versions = find_versions(versions_html_page)
    founded_versions.map { |v| Version.new(**v) }
  end

  private

  def find_versions(html_page)
    document = Nokogiri::HTML.parse(html_page)

    document.css("table tr td:nth-child(2)")
      .map { |row| row.text.strip }
      .select { |row_text| row_text.match(/[0-9]{4}-[0-9]{2}/) }
      .reverse
      .map do |version_name|
        {
          name: version_name,
          url: "#{@config[:versions_url]}/#{version_name}"
        }
      end
  end

  def versions_html_page
    Retryable.retryable(tries: 5, on: [HTTParty::Error, SocketError, OpenSSL::SSL::SSLError, Errno::ECONNRESET]) do
      HTTParty.get(@config[:versions_url])
    end
  end
end
