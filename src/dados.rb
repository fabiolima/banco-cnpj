module Dados
  DB = Sequel.connect("postgres://fabio:@127.0.0.1:5432/cnpj")

  LATIN_ENCODING = "CP1252"
  DEFAULT_ENCODING = "UTF-8"

  def prompt
    @prompt ||= TTY::Prompt.new
    @prompt
  end

  def enforce_utf8(file_path, read_as = "CP1252")
    csv_content = File.read(file_path, encoding: read_as)
    csv_content_utf8 = csv_content.encode("UTF-8").gsub("\\", "")

    StringIO.new(csv_content_utf8)
  end

  def initialize
    # Definindo um manipulador para o sinal SIGINT (CTRL+C)
    Signal.trap("INT") do
      puts "CTRL+C detectado, desconectando do banco de dados..."

      # Desconectar do banco de dados
      DB.disconnect

      # Encerrando o processo
      exit
    end
  end
end
