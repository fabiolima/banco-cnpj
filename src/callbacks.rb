module Callbacks
  def after_import(*methods)
    @after_import = methods || []
  end

  def after_import_callbacks
    @after_import
  end
end
