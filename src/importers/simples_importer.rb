# Layout do arquivo https://www.gov.br/receitafederal/dados/cnpj-metadados.pdf
# Only this file is encoded with UTF-8. All other files from Receita are Latin1 (CP1252)
class SimplesImporter < Importer
  after_import :add_index

  def initialize(*args)
    super(*args, read_as: "UTF-8")
  end

  private

  def add_index
    puts "Criando indexes para a tabela #{@table_name}"
    DB.add_index @table_name, :cnpj_basico
  end
end
