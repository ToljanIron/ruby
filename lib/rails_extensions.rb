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

  def snm_sum
    res = 0
    self.each do |eij|
      res += eij
    end
    return res
  end
end
