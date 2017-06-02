class String

  # Checks if string is Integer or Decimal value.
  def is_number?
    match_pattern = /\A[-+]?\d*\.?\d+\z/
    return true if self =~ match_pattern
    false
  end

end