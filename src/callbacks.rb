module Callbacks
  def before_import(*methods)
    @before_import = methods || []
  end

  def before_import_callbacks
    @before_import
  end

  def after_import(*methods)
    @after_import = methods || []
  end

  def after_import_callbacks
    @after_import
  end
end
