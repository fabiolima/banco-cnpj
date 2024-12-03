require "pg"
module Dados
  DB = Sequel.connect('postgres://fabio:@127.0.0.1:5432/cnpj')

  def prompt
    @prompt ||= TTY::Prompt.new
    @prompt
  end

  def enforce_utf8(file_path)
    csv_content = File.read(file_path, encoding: 'CP1252')
    csv_content_utf8 = csv_content.encode('UTF-8').gsub('\\', '')

    # Cria um StringIO com o conteúdo convertido
    io = StringIO.new(csv_content_utf8)
  end
end
