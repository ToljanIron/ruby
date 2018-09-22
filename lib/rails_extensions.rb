class String
  def is_integer?()
    true if Integer(self) rescue false
  end
end

class Hash
  def fetch_or_create(key )
    return nil, self       if key.nil?
    return self[key], self if self.key?(key)
    new_entry = yield
    self[key] = new_entry
    return new_entry, self
  end
end

class NMatrix
  #####################################################################
  # This function is used to write a specific function on each one of
  # a nmatrix rows. Typically used for normalizing values.
  #####################################################################
  def snm_map_rows
    m = []
    ii = 0
    self.each_row do |row|
      row_as_arr = row.row(0).to_a
      m << yield(row_as_arr, ii)
      ii += 1
      m
    end
    return NMatrix.new self.shape, m.flatten, dtype: self.dtype
  end

  ####################################################
  # Return sum of all matrix entries
  ####################################################
  def snm_sum
    res = 0
    self.each do |eij|
      res += eij
    end
    return res
  end

  ########################################
  # Return self raised to the 64th power
  ########################################
  def power64
    c2 = self.dot self
    c4 = c2.dot c2
    c8 = c4.dot c4
    c16 = c8.dot c8
    c32 = c16.dot c16
    c64 = c32.dot c32
    return c64
  end

  #######################################
  # matrix pretty print
  ######################################
  def pp
    rlen = self.shape[0] - 1
    clen = self.shape[1] - 1

    res = ''
    (0..rlen).each do |r|
      row = ''
      (0..clen).each do |c|
        row += " #{self[r,c]}"
      end
      res = "#{res}\n#{row}"
    end
    return res
  end

end

####################### Sanitizing methods #####################
class Object
  def is_float?
    return false if self.nil?
    return (Integer(self) != nil) rescue return false
  end

  def is_integer?
    return false if self.nil?
    return (Integer(self) != nil) rescue return false
  end

  def is_integer_or_nil?
    return true if self.nil? || self.empty?
    return (Integer(self) != nil) rescue return false
  end

  def has_no_whitespace?
    return false if self.nil?
    return self.match(/[\s]+/).nil?
  end

  def is_string_with_space?
    return false if self.nil?
    selfasarr = self.split(/\s/)
    ret = true
    selfasarr.each { |w| ret = ret &= (w.is_alphanumeric? && w != "or") }
    return ret
  end

  def is_url?
    return false if self.nil?
    return self.match(/^[a-zA-Z0-9\-\.]*$/)
  end

  def is_date?
    return false if self.nil?
    begin
      Date.parse(self)
    rescue
      return false
    end
    return true
  end

  def is_time?
    return false if self.nil?
    begin
      Time.parse(self)
    rescue
      return false
    end
    return true
  end

  def is_alphanumeric?
    return false if self.nil?
    return self.match(/[!@\#$%\^&\*)(\+=}{\\\?\s]+/).nil?
  end

  def is_alphanumeric_with_slash?
    return false if self.nil?
    return self.match(/[!@\#$%\^&\*)(\+=}{\?\s]+/).nil?
  end

  def specific_sanitize
    return self if yield
    raise "#{self} failed sanitation test"
  end

  def specific_safe_sanitize
    return self if yield
    return nil
  end

  def sanitize_url
    return specific_safe_sanitize do
      is_url?
    end
  end

  def sanitize_date
    return specific_safe_sanitize do
      is_date?
    end
  end

  def sanitize_time
    return specific_safe_sanitize do
      is_time?
    end
  end

  def safe_sanitize_integer
    return specific_safe_sanitize do
      is_integer?
    end
  end

  def sanitize_integer
    return specific_sanitize do
      is_integer?
    end
  end

  def sanitize_integer_or_nil
    return specific_sanitize do
      is_integer_or_nil?
    end
  end

  def sanitize_has_no_whitespace
    return specific_sanitize do
      has_no_whitespace?
    end
  end

  def sanitize_is_string_with_space
    return specific_sanitize do
      is_string_with_space?
    end
  end

  def sanitize_is_alphanumeric
    return specific_sanitize do
      is_alphanumeric?
    end
  end

  def sanitize_is_alphanumeric_with_slash
    return specific_sanitize do
      is_alphanumeric_with_slash?
    end
  end

end
