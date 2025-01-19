require "down"
require "ruby-progressbar"
require "rainbow/refinement"
require "fileutils"
require "zip"
require_relative "../utils"

using Rainbow

class RemoteFile
  attr_accessor :filename, :url, :save_to

  def initialize(**options)
    @config = YAML.load_file("./src/config/download.yaml").transform_keys!(&:to_sym)

    @filename = options.fetch(:filename)
    @url = options.fetch(:url)
    @save_to = "#{@config[:destination]}/#{@filename}"
  end

  def download
    return if @config[:skip_files].include? filename

    handle_existent_file(save_to)
    execute_download
    unzip_file
  end

  private

  def handle_existent_file(path)
    if File.file?(path)
      if @config[:skip_existent_files]
        puts "Arquivo #{path} já existe.".yellow
        nil
      else
        puts "Deletando #{path}.".yellow
        File.delete path
      end
    end
  end

  def execute_download
    remote_file = Down.open(url, rewindable: false)
    human_size = Utils.filesize(remote_file.size)

    progress_bar = ProgressBar.create(
      title: filename,
      total: remote_file.size,
      format: "%a [%B] %p%%"
    )

    puts "Iniciando download #{filename} - #{human_size}".cyan

    File.open(save_to, "wb") do |local_file|
      remote_file.each_chunk do |chunk|
        local_file.write(chunk)
        progress_bar.progress = progress_bar.progress + chunk.size
      end

      remote_file.close
    end

    puts "Download concluído: #{save_to}".green
  end

  def unzip_file
    file_path_csv = save_to.gsub("zip", "csv")

    handle_existent_file(file_path_csv)

    puts "Descompactando arquivo: #{save_to}"

    Zip::File.open(save_to) { |zip_file|
      zip_file.each { |f|
        FileUtils.mkdir_p(File.dirname(file_path_csv))
        zip_file.extract(f, file_path_csv) unless File.exist?(file_path_csv)
      }
    }

    puts "Arquivo descompactado: #{file_path_csv}".green
  end
end
