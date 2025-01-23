require "benchmark"
require "rainbow/refinement"

using Rainbow

# Layout do arquivo https://www.gov.br/receitafederal/dados/cnpj-metadados.pdf
class EstabelecimentoImporter < Importer
  before_import :make_cnpj_column

  def initialize(*args)
    super
  end

  private

  # Joins the first three columns into one and prepend to the row.
  def make_cnpj_column
    @files.each do |file|
      print "Iniciando processo de concatenação das colunas para geração de uma coluna cnpj no arquivo #{file}"

      elapsed_time = Benchmark.realtime do
        success = `LC_ALL=C sed -E 's/^\("\([^"]*\)"\);\("\([^"]*\)"\);\("\([^"]*\)"\)/"\\2\\4\\6";"\\2";"\\4";"\\6"/' #{file} > #{file}.temp`

        if success
          FileUtils.mv("#{file}.temp", file)
        end
      end

      print "\r✅️ Tempo gasto para concatenação #{elapsed_time.round(2)} segundos.\n"
    end
  end
end
