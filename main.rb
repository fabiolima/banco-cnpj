require "open-uri"
require "fileutils"
require "zip"
require "csv"
require "httparty"
require "nokogiri"
require "tty-prompt"
require "pg"
require "sequel"
require "benchmark"

require "./src/dados"
require "./src/importer"
require "./src/empresa_importer"

# Dir["./src/*_importer.rb"].each { |file| require file }

Importer.new("./files/Cnaes.csv", :cnae, %i(codigo descricao")).import
Importer.new("./files/Paises.csv", :pais, %i(codigo descricao")).import
Importer.new("./files/Municipios.csv", :municipio, %i(codigo descricao")).import
Importer.new("./files/Qualificacoes.csv", :qualificacao_socio, %i(codigo descricao")).import
EmpresaImporter.new("./files/Empresas*.csv", :empresa, %i(cnpj_basico razao_social natureza_juridica qualificacao_responsavel capital_social_string porte uf_responsavel)).import
