# Layout do arquivo https://www.gov.br/receitafederal/dados/cnpj-metadados.pdf
class EmpresaImporter < Importer
  after_import :fix_capital_social, :add_indexes

  def initialize(*args)
    super
  end

  private

  def fix_capital_social
    DB.add_column @table_name, :capital_social, "decimal(20, 2)", null: true
    DB << "UPDATE #{@table_name} set capital_social = CAST(replace(capital_social_string, ',', '.') as DECIMAL)"
    DB.drop_column @table_name, :capital_social_string
  end

  def add_indexes
    puts "Criando indexes para a tabela #{@table_name}"
    DB.add_index @table_name, :cnpj_basico
    DB.add_index @table_name, :razao_social
  end
end
