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

  # Captures single slash \ and duplicate \\
  def fix_literal_slashes(file_path)
    print "Corrigindo uso de barra invertida no arquivo #{file_path}..."

    elapsed_time = Benchmark.realtime do
      success = `LC_ALL=C sed 's/\\\\/\\\\\\\\/g' #{file_path} > #{file_path}.temp`

      if success
        FileUtils.mv("#{file_path}.temp", file_path)
      else
        print "\rErro ao corrigir o uso da barra invertida no arquivo #{file_path}\n".red
      end
    end

    print "\r✅️ Correção da barra invertida no arquivo #{file_path} concluída em #{elapsed_time.round(2)} segundos\n"
  end

  # Captures the 5th column and replaces the "," by "."
  # Example: "12000,00" -> "12000.00"
  def fix_decimal_separator(file_path)
    print "Corrigindo separador decimal no arquivo #{file_path}..."

    elapsed_time = Benchmark.realtime do
      success = `LC_ALL=C sed -E 's/(([^;]*;){4})([^;]*),([^;]*)(;[^;]*)/\\1\\3.\\4\\5/' #{file_path} > #{file_path}.temp`

      if success
        FileUtils.mv("#{file_path}.temp", file_path)
      else
        print "\rErro ao corrigir o separador decimal da coluna 5 no arquivo #{file_path}\n".red
      end
    end

    print "\r✅️ Correção do separador decimal do arquivo #{file_path} concluída em #{elapsed_time.round(2)} segundos\n"
  end
end
