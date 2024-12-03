module Callbacks
  def after_import(*methods)
    @after_import = methods || []
  end

  def callbacks_after_import
    @after_import
  end
end

class Importer
  include Dados

  def initialize(path_to_files, table_name, fields)
    @path_to_files, @table_name, @fields = path_to_files, table_name, fields
    @files = Dir[@path_to_files]
  end

  def self.inherited(base)
    base.extend(Callbacks)
  end

  def import
    response = prompt.yes? "Deseja começar o processo de importação para tabela '#{@table_name}'?"
    return unless response

    create_table
    puts "Iniciando a importação dos arquivos: \n -> #{@files.join("\n ->")}"

    @files.each do |file_path|
      DB.copy_into(
        @table_name,
        format: :csv,
        columns: @fields.map(&:to_sym),
        data: self.enforce_utf8(file_path),
        options: "DELIMITER ';', QUOTE '\"', ESCAPE '\\'"
      )
    end

    self.class.callbacks_after_import.each { |method| send(method) } if self.class.respond_to? :callbacks_after_import

    puts "Total de linhas importadas: #{DB[@table_name].count}"
  end

  private

  def create_table
    DB.drop_table @table_name if DB.table_exists? @table_name

    DB.create_table @table_name

    @fields.each do |field|
      DB.add_column @table_name, field, String
    end

    puts "Tabela '#{@table_name.to_s}' criada."
  end
end
