# frozen_string_literal: true
class Float
  def strip
    return to_i if to_i == self
    return self
  end
end
