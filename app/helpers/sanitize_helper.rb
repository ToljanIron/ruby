module SanitizeHelper

  def sanitize_gids(gids)
    return sanitize_ids(ids)
  end

  #################################################
  # Can accept one of:
  #   - number separated by commas
  #   - Array of numbers or strings represeting numbers
  #################################################
  def sanitize_ids(ids)
    return nil if ids.nil?
    return [] if ids == []

    if ids.class == String
      return ids if ids.match(/^[\,0-9]+$/)
    end
    raise 'Parameters not group ids' if ids.class != Array
    any_non_int = ids.any? { |e|
      !e.is_integer?
    }
    raise 'Parameter has none ints' if any_non_int
    return ids
  end

  def sanitize_alphanumeric_with_slash(s)
    return nil if s.nil?
    return s if !s.match(/[!@\#$%\^&\*)(\+=}{\?\s]+/)
    raise "Parameter is not alphanumeric with slash"
  end

  def sanitize_alphanumeric_with_space(s)
    return nil if s.nil?
    return s if s.is_string_with_space?
    raise "Parameter is not alphanumeric with space"
  end

  def sanitize_alphanumeric(s)
    return nil if s.nil?
    return s if !s.match(/[!\#\^&\*)(\+=}{\\\?\s]+/)
    raise "Parameter is not alphanumeric"
  end

  def sanitize_id(id)
    return nil if id.nil?
    return nil if id == ''
    return nil if id == 'null'
    return id if id.is_integer?
    raise "Parameter is not an id"
  end

  def sanitze_boolean(b)
    return nil if b.nil?
    return nil if b == ''
    return b if b == true || b == 'true' || b == 'True'
    return b if b == false || b == 'false' || b == 'False'
    raise "Parameter is not boolean"
  end

  def sanitize_number(n)
    return nil if n.nil?
    return nil if n == ''
    return n if n.is_float? || n.is_integer
    raise "Parameter is not boolean"
  end
end
