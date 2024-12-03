# Layout do arquivo https://www.gov.br/receitafederal/dados/cnpj-metadados.pdf
class EmpresaImporter
  include Dados

  @@files = Dir["./files/Empresas*.csv"]

  @@table_name = :empresas

  @@fields = [
    "cnpj_basico",
    "razao_social",
    "natureza_juridica",
    "qualificacao_responsavel",
    "capital_social_string",
    "porte",
    "uf_responsavel"
  ]

  def self.create_table
    DB.drop_table @@table_name if DB.table_exists? @@table_name

    DB.create_table @@table_name do
      primary_key :id
      String :cnpj_basico
      String :razao_social
      String :natureza_juridica
      String :qualificacao_responsavel
      String :capital_social_string # Será convertido para float em outra coluna.
      String :porte
      String :uf_responsavel
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

    DB.add_column @@table_name, :capital_social, "decimal(20, 2)", null: true
    DB << "UPDATE #{@@table_name} set capital_social = CAST(replace(capital_social_string, ',', '.') as DECIMAL)"
    DB.drop_column @@table_name, :capital_social_string

    puts "Empresas importadas: #{DB[:empresas].count}"
  end
end
