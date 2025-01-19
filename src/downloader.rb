require "down"
require "ruby-progressbar"
require "rainbow/refinement"
require "fileutils"
require "zip"
require "tty-prompt"
require "httparty"
require "nokogiri"
require 'retryable'
require_relative "utils"

using Rainbow

class Downloader
  def initialize(**options)
    @prompt = TTY::Prompt.new
    @skip_existent_files = options.fetch(:skip_existent_files)
    @destination = options.fetch(:destination)
    @skip_files = options.fetch(:skip_files) || []
    @versions_url = options.fetch(:versions_url)
  end

  def start
    selected_version = choose_version
    files = available_files(selected_version)

    return unless @prompt.yes?("#{files.map { |f| f[:path] }.join("\n")} \n#{files.size} arquivos encontrados. Deseja começar o download?")

    files.each do |file|
      next if @skip_files.include? file[:path]

      puts "Iniciando processo de download e descompactação para #{file[:path]}".cyan

      download_url = "#{@versions_url}/#{selected_version}#{file[:path]}"
      save_to = "#{@destination}/#{file[:path]}"

      download(download_url, save_to)
      unzip_file(save_to)
      puts "\n"
    end
  end

  private

  def available_files(chosen_version)
    version_url = "#{@versions_url}/#{chosen_version}"

    version_page = Retryable.retryable(tries: 5, on: [HTTParty::Error, SocketError, OpenSSL::SSL::SSLError, Errno::ECONNRESET]) do
      HTTParty.get(version_url)
    end

    version_doc = Nokogiri::HTML.parse(version_page)

    version_doc.css("table tr")
      .select do |row|
        anchor = row.css("td:nth-child(2) a")
        href = anchor.attribute("href")
        next if href.nil?
        href.value.match(/\w+\.zip/)
      end
      .map do |row|
        {
          path: row.css("td:nth-child(2) a").attribute("href").value,
          size: row.css("td:nth-child(4)").text
        }
      end
  end

  def choose_version
    versions_page = Retryable.retryable(tries: 5, on: [HTTParty::Error, SocketError, OpenSSL::SSL::SSLError, Errno::ECONNRESET]) do
      HTTParty.get(@versions_url)
    end

    versions_doc = Nokogiri::HTML.parse(versions_page)

    versions = versions_doc.css("table tr td:nth-child(2)")
      .map { |row| row.text.strip }
      .select { |row_text| row_text.match(/[0-9]{4}-[0-9]{2}/) }
      .reverse

    @prompt.select("Selecione a versão desejada", versions, per_page: 10)
  end

  def download(url, save_to)
    if File.file?(save_to)
      if @skip_existent_files
        puts "Arquivo #{save_to} já existe e não será baixado novamente.".yellow
        return
      else
        puts "Deletando #{save_to} para baixar novamente.".yellow
        File.delete save_to
      end
    end

    remote_file = Down.open(url, rewindable: false)
    human_size = Utils::filesize(remote_file.size)

    progress_bar = ProgressBar.create(
      title: save_to,
      total: remote_file.size,
      format: "%a [%B] %p%%"
    )

    puts "Iniciando download #{save_to} - #{human_size}".cyan

    File.open(save_to, "wb") do |local_file|
      remote_file.each_chunk do |chunk|
        local_file.write(chunk)
        progress_bar.progress = progress_bar.progress + chunk.size
      end

      remote_file.close
    end

    puts "Download concluído: #{save_to}".green
  end

  def unzip_file(file_path)
    file_path_csv = file_path.gsub("zip", "csv")

    if File.file?(file_path_csv)
      if @skip_existent_files
        puts "Arquivo #{file_path_csv} já existe. Pulando a descompactação.".yellow
        return
      else
        puts "Apagando #{file_path_csv} já existente para ser descompactado novamente.".yellow
        File.delete file_path_csv
      end
    end

    puts "Descompactando arquivo: #{file_path}"

    Zip::File.open(file_path) { |zip_file|
      zip_file.each { |f|
        FileUtils.mkdir_p(File.dirname(file_path_csv))
        zip_file.extract(f, file_path_csv) unless File.exist?(file_path_csv)
      }
    }

    puts "Arquivo descompactado: #{file_path_csv}".green
  end
end
