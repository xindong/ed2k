module Ed2k
  
  # is debuging model?
  def Ed2k.debuging?
    return $options.has_key?(:debug) && $options[:debug]
  end
    
end
