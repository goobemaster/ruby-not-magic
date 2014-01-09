module Pages
  def self.method_missing(m, *args, &block)
    if m.to_s.is_a_defined_class?
      Object.const_get(m).new
    else
      raise "Cannot instantiate undefined page: #{m} !"
    end
  end
end