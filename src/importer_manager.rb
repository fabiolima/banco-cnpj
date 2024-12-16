require_relative "schema"
require_relative "importers/importer"

Dir[__dir__ + "/importers/*_importer.rb"].sort.each { |file| require file }

class ImporterManager
  def start
    # schemas = Schema.load_all
    # SocioImporter.new(:socio, schemas["socio"]).import

    Schema.load_all.each do |table_name, config|
      clazz = config["class"].nil? ? Importer : Object.const_get(config["class"])
      clazz.new(table_name, config).import
    end
  end
end
