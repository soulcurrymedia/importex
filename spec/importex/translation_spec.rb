require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../fixtures/dummy_class.rb')
describe Importex::Base do

  before(:each) do
    @simple_class = Class.new(Importex::Base)    
    @xls_file = File.dirname(__FILE__) + '/../fixtures/simple.xls'
  end

  it "should store translation options" do
    @simple_class.column "Name"
    @simple_class.column "Age", :type => Integer
    @simple_class.translate_to DummyClass.name

    @simple_class.translated_class.should == DummyClass
  end

  it "should store translation options" do
    @simple_class.column "Name"
    @simple_class.column "Age", :type => Integer
    @simple_class.translate_to DummyClass.name

    @simple_class.import(@xls_file)

    dummy_objects = @simple_class.translate_all

    attributes = [
      {"Name" => "Foo", "Age" => 27}, # First row
      {"Name" => "Bar", "Age" => 42}, # Second row
      {"Name"=>"Blue", "Age"=>28}, # Third row
      {"Name" => "", "Age" => 25} # Fourth row
    ]

    dummy_objects.each_with_index do |dummy_object, i|
      attributes[i].each do |name, value|
        dummy_object.send(name.downcase).should == value
      end      
    end

    
  end

end