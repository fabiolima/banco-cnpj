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

Dir["./src/*_importer.rb"].each { |file| require file }

EmpresaImporter.new.import
CnaeImporter.new.import
