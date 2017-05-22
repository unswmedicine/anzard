class String

  # Checks if string is Integer or Decimal value.
  def is_number?
    match_pattern = /\A[-+]?\d*\.?\d+\z/
    return true if self =~ match_pattern
    false
  end

  # Casts to float if string is a Integer or Decimal value.
  def to_float_if_number
    return self.to_f if self.is_number?
    self
  end

end