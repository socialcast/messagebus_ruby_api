class Hash
  def without(key)
    self.dup.tap{|hash| hash.delete(key)}
  end
end