require_relative "callbacks"

class Importer
  include Dados
  extend Callbacks

  before_import :fix_encoding, :create_table
  after_import :add_indexes

  def initialize(table_name, config)
    @table_name = table_name

    @files = Dir[config["csv_files_path"]]
    @columns = config["columns"]
    @indexes = config["indexes"]
  end

  def run_before_import_callbacks
    Importer.before_import_callbacks&.each { |callback| send(callback) }

    if self.class.respond_to?(:before_import_callbacks) && self.class != Importer
      self.class.before_import_callbacks&.each { |callback| send(callback) }
    end
  end

  def run_after_import_callbacks
    Importer.after_import_callbacks&.each { |callback| send(callback) }

    if self.class.respond_to?(:after_import_callbacks) && self.class != Importer
      self.class.after_import_callbacks&.each { |callback| send(callback) }
    end
  end

  def import(&block)
    elapsed_time = Benchmark.realtime do
      run_before_import_callbacks
      read_from_csv
      run_after_import_callbacks

      block.call(DB) if block_given?
    end

    puts "Importação dos dados para a tabela #{@table_name} finalizada em #{elapsed_time} segundos."
  end

  private

  def create_table
    DB.drop_table @table_name if DB.table_exists? @table_name

    # Prevent internal conflict with @columns inside DB.create_table context
    columns = @columns

    DB.create_table @table_name.to_sym do
      primary_key(:id)

      columns.each do |col, type|
        column col.to_sym, eval(type) # rubocop:disable Security/Eval
      end
    end

    puts "Tabela '#{@table_name}' criada."
  end

  def read_from_csv
    puts "Iniciando a importação dos arquivos: \n -> #{@files.join("\n ->")}"

    @files.each do |file_path|
      DB.copy_into(
        @table_name.to_sym,
        format: :csv,
        columns: @columns.keys.map(&:to_sym),
        data: File.new(file_path),
        options: "DELIMITER ';', QUOTE '\"', ESCAPE '\\'"
      )
    end

    puts "Total de linhas importadas: #{DB[@table_name.to_sym].count}"
  end

  def add_indexes
    puts "Criando indexes para as colunas #{@indexes.join(", ")}"

    @indexes.each do |col|
      elapsed_time = Benchmark.realtime do
        DB.add_index @table_name, col.to_sym
      end

      puts "Index #{col} criado com sucesso. Tempo gasto: #{elapsed_time} segundos."
    end
  end

  def fix_encoding
    @files.each do |file_path|
      # Abrindo o arquivo de entrada (CP1252) e o arquivo de saída (UTF-8)
      File.open(file_path, "r:CP1252") do |in_file|
        File.open("#{file_path}.temp", "w:UTF-8") do |out_file|
          # Lê linha por linha do arquivo de entrada e escreve no arquivo de saída
          in_file.each_line do |line|
            out_file.puts(line)
          end
        end
      end

      FileUtils.mv("#{file_path}.temp", file_path)
    end
  end
end
