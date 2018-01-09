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
