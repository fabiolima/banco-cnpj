require "benchmark"
require "rainbow/refinement"

using Rainbow

# Layout do arquivo https://www.gov.br/receitafederal/dados/cnpj-metadados.pdf
class EmpresaImporter < Importer
  before_import :parse_csv

  def initialize(*args)
    super
  end

  private

  def parse_csv
    @files.each do |file_path|
      fix_decimal_separator file_path
      fix_literal_slashes file_path
    end
  end

  def fix_literal_slashes(file_path)
    print "Corrigindo uso de barra invertida no arquivo #{file_path}..."

    elapsed_time = Benchmark.realtime do
      # Captures single slash \ and duplicate \\
      success = `LC_ALL=C sed 's/\\\\/\\\\\\\\/g' #{file_path} > #{file_path}.temp`

      if success
        FileUtils.mv("#{file_path}.temp", file_path)
      else
        print "\rErro ao corrigir o uso da barra invertida no arquivo #{file_path}\n".red
        puts success
      end
    end

    print "\r✅️ Correção da barra invertida no arquivo #{file_path} concluída em #{elapsed_time.round(2)} segundos\n"
  end

  def fix_decimal_separator(file_path)
    print "Corrigindo separador decimal no arquivo #{file_path}..."

    elapsed_time = Benchmark.realtime do
      # Captures the 5th column and replaces the "," by "."
      # Example: "12000,00" -> "12000.00"
      success = `LC_ALL=C sed -E 's/(([^;]*;){4})([^;]*),([^;]*)(;[^;]*)/\\1\\3.\\4\\5/' #{file_path} > #{file_path}.temp`

      if success
        FileUtils.mv("#{file_path}.temp", file_path)
      else
        print "\rErro ao corrigir o separador decimal da coluna 5 no arquivo #{file_path}\n".red
        puts success
      end
    end

    print "\r✅️ Correção do separador decimal do arquivo #{file_path} concluída em #{elapsed_time.round(2)} segundos\n"
  end

  def parse_file(file)
    # puts "Iniciando correção do arquivo #{file}"

    # current_file_dir = File.dirname file
    # current_file_name = File.basename file

    # output_file_name = "#{current_file_name}.parsed"

    # csv_out = File.open("#{current_file_dir}/#{output_file_name}", "wb")

    # puts "Arquivo temporário criado #{csv_out.path}"
    # puts "Processando..."

    # CSV.foreach(file, headers: false, encoding: "UTF-8", col_sep: ";", quote_char: '"', skip_blanks: true) do |row|
    #   row[4] = row[4].gsub(",", ".") # Fix number format.

    #   new_row = row.map do |col|
    #     fixed_col = col
    #       .gsub('"', '""') # corrige o caracter " dentro das colunas
    #       .gsub("\\", "\\\\\\") # corrige o caracter / dentro das colunas, ruby usa 6 slashes pra dizer que é literal

    #     "\"#{fixed_col}\""
    #   end

    #   csv_out << new_row.join(";") + "\n"
    # end

    # csv_out.close

    # puts "Delete arquivo original #{file}"
    # File.delete file

    # puts "Renomeando arquivo corrigido #{csv_out.path} para o nome original #{file}"
    # File.rename(csv_out.path, file)
  end
end
