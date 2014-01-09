class String
  def to_class
    Kernel.const_get self
  rescue NameError
    nil
  end

  def is_a_defined_class?
    true if self.to_class
  rescue NameError
    false
  end
end