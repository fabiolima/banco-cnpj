# Layout do arquivo https://www.gov.br/receitafederal/dados/cnpj-metadados.pdf
class SocioImporter < Importer
  after_import :add_cnpj, :add_indexes

  @@final_table_name = :socio

  def initialize(*args)
    super
  end

  private

  # Create new table "socio" based on "socio_original" but with full CNPJ
  def add_cnpj
    # Add index to speed up joins
    DB.add_index @table_name, :cnpj_basico

    DB.drop_table? @@final_table_name

    # Creates new table with CNPJ field from "estabelecimento" join
    DB << "
      CREATE TABLE socio AS
      SELECT te.cnpj as cnpj, ts.*
      FROM socio_original ts
      LEFT JOIN estabelecimento te ON te.cnpj_basico = ts.cnpj_basico
      WHERE te.matriz_filial='1';
    "

    # Remove original table "socio_original"
    DB.drop_table @table_name
  end

  def add_indexes
    puts "Criando indexes para a tabela #{@@final_table_name}"
    DB.add_index @@final_table_name, :cnpj
    DB.add_index @@final_table_name, :cnpj_cpf_socio
    DB.add_index @@final_table_name, :nome_socio
    DB.add_index @@final_table_name, :representante_legal
    DB.add_index @@final_table_name, :nome_representante
  end
end
