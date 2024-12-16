# Layout do arquivo https://www.gov.br/receitafederal/dados/cnpj-metadados.pdf
class SocioImporter < Importer
  # after_import :add_cnpj

  @@final_table_name = :socio_join

  def initialize(*args)
    super
  end

  private

  def add_cnpj
    DB.drop_table? @@final_table_name

    DB << "
      CREATE TABLE socio_join AS
      SELECT te.cnpj as cnpj, ts.*
      FROM socio ts
      LEFT JOIN estabelecimento te ON te.cnpj_basico = ts.cnpj_basico
      WHERE te.matriz_filial='1';
    "
  end
end
