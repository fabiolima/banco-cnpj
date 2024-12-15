require_relative "callbacks"

class Importer
  include Dados

  def initialize(table_name, config)
    @table_name = table_name

    @files = Dir[config["csv_files_path"]]
    @columns = config["columns"]
    @indexes = config["indexes"]
    @primary_key = config["primary_key"]

    @options = {}
    @options[:read_as] = config.fetch(:read_as, LATIN_ENCODING)
  end

  def self.inherited(base)
    base.extend(Callbacks)
  end

  def import(&block)
    response = prompt.yes? "Deseja começar o processo de importação para tabela '#{@table_name}'?"
    return unless response

    create_table @table_name, @primary_key, @columns, @indexes

    elapsed_time = Benchmark.realtime do
      read_from_csv @columns, @options
    end

    puts "Importação dos dados finalizada em #{elapsed_time} segundos."

    # Run callbacks if there are any
    if self.class.respond_to? :after_import_callbacks
      self.class.after_import_callbacks&.each { |method| send(method) }
    end

    block.call(DB) if block_given?
  end

  private

  def create_table(table_name, primary_key, columns, indexes)
    DB.drop_table table_name if DB.table_exists? table_name

    DB.create_table table_name.to_sym do
      primary_key(:id)

      columns.each do |col, type|
        column col.to_sym, eval(type) # rubocop:disable Security/Eval
      end

      indexes.each do |col|
        index col.to_sym
      end
    end

    puts "Tabela '#{@table_name}' criada."
  end

  def resolve_file(file_path, encoding)
    # return enforce_utf8(file_path) if encoding == LATIN_ENCODING

    File.new(file_path)
  end

  def read_from_csv(columns, options)
    puts "Iniciando a importação dos arquivos: \n -> #{@files.join("\n ->")}"

    puts "total de colunas " + columns.keys.size.to_s

    @files.each do |file_path|
      file = resolve_file file_path, options[:read_as]

      DB.copy_into(
        @table_name.to_sym,
        format: :csv,
        columns: columns.keys.map(&:to_sym),
        data: file,
        options: "DELIMITER ';', QUOTE '\"', ESCAPE '\\'"
      )
    end

    puts "Total de linhas importadas: #{DB[@table_name.to_sym].count}"
  end
end
