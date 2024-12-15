# Layout do arquivo https://www.gov.br/receitafederal/dados/cnpj-metadados.pdf
class EstabelecimentoImporter < Importer
  after_import :add_cnpj

  def initialize(*args)
    super
  end

  private

  def add_cnpj
    # puts "Criando coluna CNPJ concatenando os valores de cnpj_basico, cnpj_ordem e cnpj_dv"
    # DB.add_column @table_name, :cnpj, :text
    # DB << "UPDATE #{@table_name} set cnpj = cnpj_basico || cnpj_ordem || cnpj_dv"

    # puts "Criando index para CNPJ na tabela #{@table_name}"
    # DB.add_index @table_name, :cnpj
  end
end
