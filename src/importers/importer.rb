require "csv"
require "pg"
require "sequel"
require "benchmark"
require "rainbow/refinement"

require_relative "../callbacks"
using Rainbow

class Importer
  extend Callbacks

  before_import :fix_files
  after_import :add_indexes

  def initialize(table_name, config)
    @table_name = table_name

    @files = Dir[config["csv_files_path"]]
    @columns = config["columns"]
    @indexes = config["indexes"]

    start_database_connection
  end

  def start_database_connection
    config = YAML.load_file("./src/config/database.yaml").transform_keys!(&:to_sym)
    @database = Sequel.connect(config[:database_url])

    Signal.trap("INT") do
      puts "CTRL+C detectado, desconectando do banco de dados..."
      @database.disconnect
      exit
    end
  end

  def import(&block)
    run_before_import_callbacks
    read_from_csv
    run_after_import_callbacks
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
    @database.drop_table @table_name if @database.table_exists? @table_name

    # Prevent internal conflict with @columns inside @database.create_table context
    columns = @columns

    @database.create_table @table_name.to_sym do
      primary_key(:id)

      columns.each do |col, type|
        column col.to_sym, type
      end
    end

    puts "Tabela '#{@table_name}' criada."
  end

  def read_from_csv
    create_table

    @files.each do |file_path|
      print "\rImportando arquivo: #{file_path.cyan} para a tabela #{@table_name.cyan}"

      elapsed_time = Benchmark.realtime do
        @database.copy_into(
          @table_name.to_sym,
          format: :csv,
          columns: @columns.keys.map(&:to_sym),
          data: File.new(file_path),
          options: "DELIMITER ';', QUOTE '\"', ESCAPE '\\'"
        )
      end

      print "\r✅️ Importação do arquivo #{file_path.cyan} para a tabela #{@table_name.cyan} concluída em #{elapsed_time.round(2)} segundos.\n"
    end

    puts "Importação da tabela #{@table_name.cyan} concluída. Total de linhas importadas: #{@database[@table_name.to_sym].count.to_s.green}"
  end

  def add_indexes
    @indexes.each do |col|
      print "\rCriando index para a coluna #{col.cyan} na tabela #{@table_name.cyan}"

      elapsed_time = Benchmark.realtime do
        @database.add_index @table_name, col.to_sym
      end

      print "\r✅️ Index para coluna #{col.cyan} na tabela #{@table_name.cyan} criado com sucesso em #{elapsed_time.round(2)} segundos.\n"
    end
  end

  def fix_files
    @files.each do |file_path|
      remove_multiple_spaces(file_path)
      fix_encoding(file_path)
      fix_literal_slashes(file_path)
      remove_isolated_quote(file_path)
    end
  end

  # Captures quotes that confuses PostgreSQL.
  # Example: "aaaa"bb"
  def remove_isolated_quote(file_path)
    print "Removendo caracteres de mal formação no arquivo #{file_path}"

    elapsed_time = Benchmark.realtime do
      success = `LC_ALL=C sed -E 's/^""([^;]*)/\"\\1/; s/; ""([^;]*)/; \"\\1/g' #{file_path} > #{file_path}.temp`

      if success
        FileUtils.mv("#{file_path}.temp", file_path)
      end
    end

    print "\r✅️ Remoção de caracteres no arquivo #{file_path} concluída em #{elapsed_time.round(2)} segundos.\n"
  end

  # Captures single slash \ and duplicate \\
  def fix_literal_slashes(file_path)
    print "Corrigindo uso de barra invertida no arquivo #{file_path}..."

    elapsed_time = Benchmark.realtime do
      success = `LC_ALL=C sed 's/\\\\/\\\\\\\\/g' #{file_path} > #{file_path}.temp`

      if success
        FileUtils.mv("#{file_path}.temp", file_path)
      else
        print "\rErro ao corrigir o uso da barra invertida no arquivo #{file_path}\n".red
      end
    end

    print "\r✅️ Correção da barra invertida no arquivo #{file_path} concluída em #{elapsed_time.round(2)} segundos\n"
  end

  # Remove multiple spaces using sed command.
  # See https://stackoverflow.com/questions/19242275/re-error-illegal-byte-sequence-on-mac-os-x
  # to understand the LC_ALL trick.
  def remove_multiple_spaces(file_path)
    print "Limpando arquivo #{file_path}..."

    elapsed_time = Benchmark.realtime do
      success = `LC_ALL=C sed 's/[ ][ ]*/ /g' #{file_path} > #{file_path}.temp`

      if success
        FileUtils.mv("#{file_path}.temp", file_path)
      else
        print "\rErro ao remover multiplos espaços arquivo #{file_path}\n".red
      end
    end

    print "\r✅️ Limpeza do arquivo #{file_path} concluída em #{elapsed_time.round(2)} segundos\n"
  end

  # Files from Receita Federal are wrongly encoded as Latin1 even with characters from UTF-8
  # It is better to convert them as UTF-8 before import.
  # This method uses UNIX iconv command and sed for removing unprintable characters.
  def fix_encoding(file_path)
    print "Convertendo #{file_path} para UTF-8..."

    elapsed_time = Benchmark.realtime do
      success = `iconv -f latin1 -t UTF-8//TRANSLIT #{file_path} | sed 's/[^[:print:]\t]//g' > #{file_path}.temp`

      if success
        FileUtils.mv("#{file_path}.temp", file_path)
      else
        print "\rErro ao converter arquivo #{file_path} para UTF-8\n".red
      end
    end

    print "\r✅️ Conversão do arquivo #{file_path} para UTF-8 concluída em #{elapsed_time.round(2)} segundos.\n"
  end
end
