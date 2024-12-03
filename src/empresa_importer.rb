# Layout do arquivo https://www.gov.br/receitafederal/dados/cnpj-metadados.pdf
class EmpresaImporter < Importer
  after_import :fix_capital_social

  def initialize(*args)
    super(*args)
  end

  def fix_capital_social
    DB.add_column @table_name, :capital_social, "decimal(20, 2)", null: true
    DB << "UPDATE #{@table_name} set capital_social = CAST(replace(capital_social_string, ',', '.') as DECIMAL)"
    DB.drop_column @table_name, :capital_social_string
  end
end
