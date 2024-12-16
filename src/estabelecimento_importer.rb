require "csv"

# Layout do arquivo https://www.gov.br/receitafederal/dados/cnpj-metadados.pdf
class EstabelecimentoImporter < Importer
  before_import :parse_csv

  def initialize(*args)
    super
  end

  private

  def parse_csv
    puts "entrei no parse csv tbm"
    @files.each do |file|
      result = Benchmark.realtime do
        parse_file file
      end

      puts "Correção do arquivo finalizada em #{result} segundos."
    end
  end

  def parse_file(file)
    puts "Iniciando correção do arquivo #{file}"

    current_file_dir = File.dirname file
    current_file_name = File.basename file

    output_file_name = "#{current_file_name}.parsed"

    csv_out = File.open("#{current_file_dir}/#{output_file_name}", "wb")

    puts "Arquivo temporário criado #{csv_out.path}"
    puts "Processando..."

    index = 0
    CSV.foreach(file, headers: false, encoding: "CP1252", col_sep: ";", quote_char: '"', skip_blanks: true) do |row|
      break if index == 1_000_000
      # puts row
      cnpj = row[0] + row[1] + row[2]

      new_row = [cnpj, *row]

      new_row = new_row.map do |col|
        fixed_col = col
          .gsub('"', '""') # corrige o caracter " dentro das colunas
          .gsub("\\", "\\\\\\") # corrige o caracter / dentro das colunas, ruby usa 6 slashes pra dizer que é literal

        "\"#{fixed_col}\""
      end

      begin
        csv_out << new_row.join(";").encode("utf-8") + "\n"
      rescue => error
        puts error.message

        fallback = {
          "\u0081" => "\x81".force_encoding("CP1252"),
          "\u008D" => "\x8D".force_encoding("CP1252"),
          "\u008F" => "\x8F".force_encoding("CP1252"),
          "\u0090" => "\x90".force_encoding("CP1252"),
          "\u009D" => "\x9D".force_encoding("CP1252")
        }

        fixed_encoding = new_row.join(";").encode("CP1252", fallback: fallback).force_encoding("UTF-8") + "\n"

        csv_out << fixed_encoding
      end

      index += 1
    end

    csv_out.close

    puts "Delete arquivo original #{file}"
    File.delete file

    puts "Renomeando arquivo corrigido #{csv_out.path} para o nome original #{file}"
    File.rename(csv_out.path, file)
  end
end
