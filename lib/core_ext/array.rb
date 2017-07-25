class Array

  # Returns true when array contains string that is not an Integer or Decimal value.
  def contains_non_numerical_string?
    self.each do |item|
      if item.is_a?(String) && !item.is_number?
        return true
      end
    end
    false
  end
end