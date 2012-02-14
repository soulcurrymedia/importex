class DummyClass
  attr_accessor :name
  attr_accessor :age
  attr_accessor :older
  attr_accessor :younger

  def initialize
    self.older = []
    self.younger = []
  end

  def younger_count
    self.younger.count
  end

  def older_count
    self.older.count
  end

end