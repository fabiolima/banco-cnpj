class Downloader
  @@prompt = TTY::Prompt.new

  VERSIONS_URL = "https://arquivos.receitafederal.gov.br/dados/cnpj/dados_abertos_cnpj"

  DESTINATION = "./files"

  EXCLUDE_FILES = [
    "Empresas0.zip",
    "Empresas2.zip",
    "Empresas3.zip",
    "Empresas4.zip",
    "Empresas5.zip",
    "Empresas6.zip",
    "Empresas7.zip",
    "Empresas8.zip",
    "Empresas9.zip",
    "Estabelecimentos0.zip",
    "Estabelecimentos2.zip",
    "Estabelecimentos3.zip",
    "Estabelecimentos4.zip",
    "Estabelecimentos5.zip",
    "Estabelecimentos6.zip",
    "Estabelecimentos7.zip",
    "Estabelecimentos8.zip",
    "Estabelecimentos9.zip",
    "Socios0.zip",
    "Socios2.zip",
    "Socios3.zip",
    "Socios4.zip",
    "Socios5.zip",
    "Socios6.zip",
    "Socios7.zip",
    "Socios8.zip",
    "Socios9.zip"
  ]

  def start
    chosen_version = choose_version
    files = available_files(chosen_version)

    start_download = @@prompt.yes?("#{files.map { |f| f[:path] }.join("\n")} \n#{files.size} arquivos encontrados. Deseja começar o download?")

    puts "\nProcesso encerrado." unless start_download

    files.each do |file|
      next if EXCLUDE_FILES.include? file[:path]

      filename = file[:path]
      file_url = "#{VERSIONS_URL}/#{chosen_version}#{filename}"

      puts "Iniciando download #{filename} - #{file[:size]}"

      if File.file? "#{DESTINATION}/#{filename}"
        puts "Arquivo #{filename} já existe na pasta ./files"
      else
        download(file_url, "#{DESTINATION}/#{filename}")
        puts "Download concluído: #{filename} ✅"
      end

      csv_filename = filename.gsub("zip", "csv")

      if File.file? "#{DESTINATION}/#{csv_filename}"
        puts "Arquivo #{csv_filename} já existe na pasta .files/. Apagando para descompactar novamente."
        File.delete "#{DESTINATION}/#{csv_filename}"
      end

      puts "Descompactando arquivo: #{filename}"
      unzip_file("#{DESTINATION}/#{filename}", DESTINATION, csv_filename)
      puts "Arquivo descompactado: #{csv_filename}"
    end
  end

  private

  def available_files(chosen_version)
    # Página da versão selecionada
    version_url = "#{VERSIONS_URL}/#{chosen_version}"

    version_page = HTTParty.get(version_url)
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
    versions_page = HTTParty.get(VERSIONS_URL)
    versions_doc = Nokogiri::HTML.parse(versions_page)

    versions = versions_doc.css("table tr td:nth-child(2)")
      .map { |row| row.text.strip }
      .select { |row_text| row_text.match(/[0-9]{4}-[0-9]{2}/) }
      .reverse

    @@prompt.select("Selecione a versão desejada", versions, per_page: 10)
  end

  def download(url, path)
    case io = OpenURI.open_uri(url)
    when StringIO then File.write(path, io.read)
    when Tempfile then io.close
                       FileUtils.mv(io.path, path)
    end
  end

  def unzip_file(file, destination, save_as)
    Zip::File.open(file) { |zip_file|
      zip_file.each { |f|
        f_path = File.join(destination, save_as)
        FileUtils.mkdir_p(File.dirname(f_path))
        zip_file.extract(f, f_path) unless File.exist?(f_path)
      }
    }
  end
end
