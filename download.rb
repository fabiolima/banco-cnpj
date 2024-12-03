require "open-uri"
require "fileutils"
require "zip"
require "csv"
require "httparty"
require "nokogiri"
require "tty-prompt"

HTTParty::Response.class_eval do
  def warn_about_nil_deprecation
  end
end

prompt = TTY::Prompt.new

# Página das versões
versions_url = "https://arquivos.receitafederal.gov.br/dados/cnpj/dados_abertos_cnpj"
versions_page = HTTParty.get(versions_url)
versions_doc = Nokogiri::HTML.parse(versions_page)

versions = versions_doc.css("table tr td:nth-child(2)")
  .map { |row| row.text.strip }
  .select { |row_text| row_text.match /[0-9]{4}-[0-9]{2}/ }
  .reverse

chosen_version = prompt.select("Selecione a versão desejada", versions, per_page: 10)


# Página da versão selecionada
version_url = "#{versions_url}/#{chosen_version}"

version_page = HTTParty.get(version_url)
version_doc = Nokogiri::HTML.parse(version_page)

available_files = version_doc.css("table tr")
  .select do |row|
    anchor = row.css("td:nth-child(2) a")
    href = anchor.attribute("href")
    next if href.nil?
    href.value.match /\w+\.zip/
  end
  .map do |row|
    {
      path: row.css("td:nth-child(2) a").attribute("href").value,
      size: row.css("td:nth-child(4)").text
    }
  end

proceed_download = prompt.yes?("#{available_files.map { |f| f[:path] }.join("\n")} \n#{available_files.size} arquivos encontrados. Deseja começar o download?")

puts "\nProcesso encerrado." unless proceed_download

puts "\n"

available_files.each do |file|
  puts "Baixando #{file[:path]} - #{file[:size]} \n"
  puts "#{file[:path]} ✅\n"
end

# chosen_file = prompt.select("Selecione o arquivo desejado", available_files)


# puts proceed_download

# puts rows
#
# rows.each do |item|
#   puts item.text
# end







# def download(url, path)
#   case io = OpenURI::open_uri(url)
#   when StringIO then File.open(path, 'w') { |f| f.write(io.read) }
#   when Tempfile then io.close; FileUtils.mv(io.path, path)
#   end
# end

# url = "https://arquivos.receitafederal.gov.br/dados/cnpj/dados_abertos_cnpj/2024-11/Empresas1.zip"
# path = "./files/Empresas1.zip"
# # download(url, path)

# def unzip_file (file, destination)
#   Zip::File.open(file) { |zip_file|
#    zip_file.each { |f|
#      f_path=File.join(destination, f.name)
#      FileUtils.mkdir_p(File.dirname(f_path))
#      zip_file.extract(f, f_path) unless File.exist?(f_path)
#    }
#   }
# end

# # unzip_file("./files/Empresas1.zip", "./files")
# csv_file = "./files/K3241.K03200Y1.D41109.EMPRECSV"

# CSV.foreach(csv_file, col_sep: ";", encoding: "CP1252") do |row, index|
#   puts "asd"
# end
