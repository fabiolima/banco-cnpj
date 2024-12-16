class Schema
  FILE_PATHS = "./src/schemas/*.yaml".freeze

  def self.load_all
    schema_files = Dir[FILE_PATHS]

    schema_files.each_with_object({}) do |file, result|
      data = YAML.load_file(file)
      result.merge!(data)
    end
  end
end
