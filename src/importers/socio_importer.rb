require "benchmark"
require "rainbow/refinement"

using Rainbow

# Layout do arquivo https://www.gov.br/receitafederal/dados/cnpj-metadados.pdf
class SocioImporter < Importer
  after_import :join_estabelecimento

  def initialize(*args)
    super
  end

  private

  def join_estabelecimento
    print "Iniciando join da tabela sócio com estabelecimento"

    elapsed_time = Benchmark.realtime do
      tmp_table_name = "socio_join"

      @database.drop_table tmp_table_name if @database.table_exists? tmp_table_name

      # Create table joining with estabelecimento.
      @database << "
        CREATE TABLE #{tmp_table_name} AS
        SELECT te.cnpj as cnpj, ts.*
        FROM socio ts
        LEFT JOIN estabelecimento te ON te.cnpj_basico = ts.cnpj_basico
        WHERE te.matriz_filial='1';
      "

      # Drop socio's table.
      @database.drop_table @table_name

      # Rename the join table to original table name.
      @database << "ALTER TABLE #{tmp_table_name} RENAME TO #{@table_name};"

      add_indexes
    end

    print "\r✅️ Join da tabela sócio x estabelecimento concluído em #{elapsed_time.round(2)} segundos.\n"
  end
end
