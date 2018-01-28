module Asspects extend ActiveSupport::Concern
  ##################################################################
  # Generic cache for this controller. First generate a cache key
  #   from the params (sp), then look for it and add it to the cache
  #   if it doesn't exist.
  ##################################################################
  def measures_cache_result(api_name, sp)
    cache_key = sp.keys.inject(api_name) { |m, k| m = "#{m}-#{k}-#{sp[k]}" }
    res = cache_read(cache_key)
    if res.nil?
      res = yield
      cache_write(cache_key, res)
    end
    return res
  end

  ##################################
  # Same render patter in all calls
  ##################################
  def measures_return_result
    res = yield
    res = Oj.dump(res)
    render json: res
  end
end
