require_relative "callbacks"

class Importer
  include Dados

  def initialize(path_to_files, table_name, fields, **options)
    @path_to_files, @table_name, @fields = path_to_files, table_name, fields
    @files = Dir[@path_to_files]

    @options = {}
    @options[:read_as] = options.fetch(:read_as, LATIN_ENCODING)
  end

  def self.inherited(base)
    base.extend(Callbacks)
  end

  def import(&block)
    response = prompt.yes? "Deseja começar o processo de importação para tabela '#{@table_name}'?"
    return unless response

    create_table
    read_from_csv

    # Run callbacks if there are any
    if self.class.respond_to? :after_import_callbacks
      self.class.after_import_callbacks.each { |method| send(method) } unless self.class.after_import_callbacks.nil?
    end

    block.call(DB) if block_given?
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

  def read_from_csv
    puts "Iniciando a importação dos arquivos: \n -> #{@files.join("\n ->")}"

    @files.each do |file_path|
      file = @options[:read_as] == LATIN_ENCODING ? self.enforce_utf8(file_path) : File.new(file_path, encoding: DEFAULT_ENCODING)

      DB.copy_into(
        @table_name,
        format: :csv,
        columns: @fields.map(&:to_sym),
        data: file,
        options: "DELIMITER ';', QUOTE '\"', ESCAPE '\\'"
      )
    end

    puts "Total de linhas importadas: #{DB[@table_name].count}"
  end
end
