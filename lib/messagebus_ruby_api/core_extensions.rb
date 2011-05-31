class String
  def mb_camelize
    self.split(/[^a-z0-9]/i).map(&:capitalize).join.tap { |string| string[0, 1] = string[0, 1].downcase }
  end
end
