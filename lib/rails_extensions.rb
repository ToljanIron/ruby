class Hash
  def fetch_or_create(key )
    return nil, self       if key.nil?
    return self[key], self if self.key?(key)
    new_entry = yield
    self[key] = new_entry
    return new_entry, self
  end
end
