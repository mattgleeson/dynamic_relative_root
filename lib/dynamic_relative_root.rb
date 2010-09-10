class DynamicRelativeRoot
  @@matcher = nil
  cattr_accessor :matcher
  @@current = nil
  cattr_accessor :current
  @@current_root = nil
  cattr_accessor :current_root
  attr_accessor :root

  def initialize(request_path)
    @request_path = request_path
    @root = ''
    @@current = self
  end

  def path
    if @request_path =~ @@matcher
      @root = $1 or raise "no capture in matcher!"
      @request_path.sub(@root, '')
    else
      @request_path
    end
  end

  def current_root
    if @@current_root
      @@current_root
    elsif @@current
      @@current.root
    else
      ''
    end
  end
end

ActionController::Base.after_filter do
  DynamicRelativeRoot.current = nil
end

class ActionController::AbstractRequest
  attr_accessor :dynamic_relative_root

  def path_with_dynamic_relative_root(*args)
    path = path_without_dynamic_relative_root(*args)
    @dynamic_relative_root = DynamicRelativeRoot.new(path)
    @dynamic_relative_root.path
  end
  alias_method_chain :path, :dynamic_relative_root
end

class ActionController::Routing::RouteSet
  def generate_with_dynamic_relative_root(*args)
    path = generate_without_dynamic_relative_root(*args)
    if path && path.is_a?(String) && DynamicRelativeRoot.current_root
      path = DynamicRelativeRoot.current_root + path
    end
    path
  end
  alias_method_chain :generate, :dynamic_relative_root
end

