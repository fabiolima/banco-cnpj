# Layout do arquivo https://www.gov.br/receitafederal/dados/cnpj-metadados.pdf
class EmpresaImporter < Importer
  before_import :parse_csv

  def initialize(*args)
    super
  end

  private

  def parse_csv
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

    CSV.foreach(file, headers: false, encoding: "UTF-8", col_sep: ";", quote_char: '"', skip_blanks: true) do |row|
      row[4] = row[4].gsub(",", ".") # Fix number format.

      new_row = row.map do |col|
        fixed_col = col
          .gsub('"', '""') # corrige o caracter " dentro das colunas
          .gsub("\\", "\\\\\\") # corrige o caracter / dentro das colunas, ruby usa 6 slashes pra dizer que é literal

        "\"#{fixed_col}\""
      end

      csv_out << new_row.join(";") + "\n"
    end

    csv_out.close

    puts "Delete arquivo original #{file}"
    File.delete file

    puts "Renomeando arquivo corrigido #{csv_out.path} para o nome original #{file}"
    File.rename(csv_out.path, file)
  end
end
