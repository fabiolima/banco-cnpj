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
require "yaml"
require_relative "src/dados"
require_relative "src/importer"
require_relative "src/downloader"
require_relative "src/estabelecimento_importer"

# Dir["./src/*_importer.rb"].sort.each { |file| require file }

# Stop annoying warning
# See https://github.com/jnunemaker/httparty/issues/568
HTTParty::Response.class_eval do
  def warn_about_nil_deprecation
  end
end

Downloader.new.start

schema = YAML.load_file("schema.yaml")

schema.each do |table_name, config|
  clazz = config["class"].nil? ? Importer : Object.const_get(config["class"])

  clazz.new(table_name, config).import
end


# Importer.new("./files/Cnaes.csv", :cnae, %i(codigo descricao")).import do |database| database.add_index :cnae, :codigo end
# Importer.new("./files/Paises.csv", :pais, %i(codigo descricao")).import do |database| database.add_index :pais, :codigo end
# Importer.new("./files/Motivos.csv", :motivo, %i(codigo descricao")).import do |database| database.add_index :motivo, :codigo end
# Importer.new("./files/Naturezas.csv", :natureza,  %i(codigo descricao)).import do |database| database.add_index :natureza, :codigo end
# Importer.new("./files/Municipios.csv", :municipio, %i(codigo descricao")).import do |database| database.add_index :municipio, :codigo end
# Importer.new("./files/Qualificacoes.csv", :qualificacao_socio, %i(codigo descricao")).import do |database| database.add_index :qualificacao_socio, :codigo end
# EstabelecimentoImporter.new("./files/Estabelecimentos*.csv", :estabelecimento, %i(cnpj_basico cnpj_ordem cnpj_dv matriz_filial nome_fantasia situacao_cadastral data_situacao_cadastral motivo_situacao_cadastral nome_cidade_exterior pais data_inicio_atividades cnae_fiscal cnae_fiscal_secundaria tipo_logradouro logradouro  numero complemento bairro cep uf municipio ddd1  telefone1 ddd2  telefone2 ddd_fax  fax correio_eletronico situacao_especial data_situacao_especial)).import
# EmpresaImporter.new("./files/Empresas*.csv", :empresa, %i(cnpj_basico razao_social natureza_juridica qualificacao_responsavel capital_social_string porte uf_responsavel)).import
# SocioImporter.new("./files/Socios*.csv", :socio_original, %i(cnpj_basico identificador_de_socio nome_socio cnpj_cpf_socio qualificacao_socio data_entrada_sociedade pais representante_legal nome_representante qualificacao_representante_legal faixa_etaria)).import
# SimplesImporter.new("./files/Simples.csv", :simples, %i(cnpj_basico opcao_simples data_opcao_simples data_exclusao_simples opcao_mei data_opcao_mei data_exclusao_mei)).import
