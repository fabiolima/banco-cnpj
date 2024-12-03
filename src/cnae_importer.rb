# Layout do arquivo https://www.gov.br/receitafederal/dados/cnpj-metadados.pdf
class CnaeImporter
  include Dados

  @@files = Dir["./files/Cnaes.csv"]

  @@table_name = :cnaes

  @@fields = [
    "codigo",
    "descricao"
  ]

  def self.files
    Dir[@@filename_like]
  end

  def self.create_table
    DB.drop_table @@table_name if DB.table_exists? @@table_name

    DB.create_table @@table_name do
      primary_key :id
      String :codigo
      String :descricao
    end

    puts "Tabela '#{@@table_name.to_s}' criada."
  end

  def import
    response = prompt.yes? "Deseja começar o processo de importação para tabela '#{@@table_name}'?"
    return unless response

    self.class.create_table
    puts "Iniciando a importação dos arquivos: \n -> #{@@files.join("\n ->")}"

    @@files.each do |file_path|
      DB.copy_into(
        @@table_name,
        format: :csv,
        columns: @@fields.map(&:to_sym),
        data: self.enforce_utf8(file_path),
        options: "DELIMITER ';', QUOTE '\"', ESCAPE '\\'"
      )
    end

    puts "CNAEs importadas: #{DB[@@table_name].count}"
  end
end
