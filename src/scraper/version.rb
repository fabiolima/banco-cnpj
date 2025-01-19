require "httparty"
require "nokogiri"
require "retryable"

require_relative "remote_file"

class Version
  attr_accessor :name, :url

  def initialize(**options)
    @name = options.fetch(:name)
    @url = options.fetch(:url)
  end

  def files
    founded_files = find_files
    founded_files.map { |f| RemoteFile.new(**f) }
  end

  private

  def find_files
    document = Nokogiri::HTML.parse(version_html_page)

    document.css("table tr")
      .select do |row|
        anchor = row.css("td:nth-child(2) a")
        href = anchor.attribute("href")
        next if href.nil?
        href.value.match(/\w+\.zip/)
      end
      .map do |row|
        filename = row.css("td:nth-child(2) a").attribute("href").value
        file_url = "#{url}#{filename}"

        {
          filename: filename,
          url: file_url
        }
      end
  end

  def version_html_page
    Retryable.retryable(tries: 5, on: [HTTParty::Error, SocketError, OpenSSL::SSL::SSLError, Errno::ECONNRESET]) do
      HTTParty.get(url)
    end
  end
end
