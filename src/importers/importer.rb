require_relative "../callbacks"
require_relative "../dados"
using Rainbow

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

  def import(&block)
    elapsed_time = Benchmark.realtime do
      run_before_import_callbacks
      read_from_csv
      # run_after_import_callbacks

      # block.call(DB) if block_given?
    end

    puts "Importação dos dados para a tabela #{@table_name} finalizada em #{elapsed_time} segundos.".green
  end

  private

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

  def create_table
    DB.drop_table @table_name if DB.table_exists? @table_name

    # Prevent internal conflict with @columns inside DB.create_table context
    columns = @columns

    DB.create_table @table_name.to_sym do
      primary_key(:id)

      columns.each do |col, type|
        column col.to_sym, type # rubocop:disable Security/Eval
      end
    end

    puts "Tabela '#{@table_name}' criada."
  end

  def read_from_csv
    @files.each do |file_path|
      puts "Iniciando a importação do arquivo arquivos: #{file_path.cyan}"

      DB.copy_into(
        @table_name.to_sym,
        format: :csv,
        columns: @columns.keys.map(&:to_sym),
        data: File.new(file_path),
        options: "DELIMITER ';', QUOTE '\"', ESCAPE '\\'"
      )

      puts "Total de linhas importadas do arquivo #{file_path}: #{DB[@table_name.to_sym].count}".green
    end

    puts "Total de linhas importadas(de todos os arquivos): #{DB[@table_name.to_sym].count}".green
  end

  def add_indexes
    puts "Criando indexes para as colunas #{@indexes.join(", ")}".cyan

    @indexes.each do |col|
      elapsed_time = Benchmark.realtime do
        DB.add_index @table_name, col.to_sym
      end

      puts "Index #{col} criado com sucesso. Tempo gasto: #{elapsed_time} segundos.".green
    end
  end

  def detect_charset(file_path)
    `file --mime #{file_path}`.strip.split('charset=').last
  rescue => e
    Rails.logger.warn "Unable to determine charset of #{file_path}"
    Rails.logger.warn "Error: #{e.message}"
  end

  def fix_encoding
    @files.each do |file_path|
      # puts "Convertendo #{file_path} para UTF-8".cyan

      # puts "Charset detectado: #{detect_charset file_path}".red

      # elapsed_time = Benchmark.realtime do
      #   success = `iconv -f latin1 -t UTF-8 #{file_path} > #{file_path}.temp`

      #   puts success
      #   if success
      #     puts "converti com sucesso".green
      #   end
      # end

      # FileUtils.mv("#{file_path}.temp", file_path)
      # puts "Correção finalizada em #{elapsed_time} segundos.".green
    end





    # @files.each do |file_path|
    #   File.open(file_path, "r:CP1252") do |in_file|
    #     File.open("#{file_path}.temp", "w:UTF-8") do |out_file|
    #       in_file.each_line do |line|
    #         out_file.puts(line)
    #       end
    #     end
    #   end

    #   FileUtils.mv("#{file_path}.temp", file_path)
    # end
  end
end
