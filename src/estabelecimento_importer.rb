# Layout do arquivo https://www.gov.br/receitafederal/dados/cnpj-metadados.pdf
class EstabelecimentoImporter < Importer
  after_import :add_cnpj

  def initialize(*args)
    super(*args)
  end

  private

  def add_cnpj
    DB.add_column @table_name, :cnpj, :text
    DB << "UPDATE #{@table_name} set cnpj = cnpj_basico || cnpj_ordem || cnpj_dv"

    puts "Criando indexes para a tabela #{@table_name}"
    DB.add_index @table_name, :cnpj
    DB.add_index @table_name, :cnpj_basico
    DB.add_index @table_name, :nome_fantasia
  end
end
