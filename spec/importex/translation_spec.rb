require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../fixtures/dummy_class.rb')
require File.expand_path(File.dirname(__FILE__) + '/../fixtures/import_class1.rb')
describe Importex::Base do

  before(:each) do
    @xls_file = File.dirname(__FILE__) + '/../fixtures/simple.xls'
  end

  after(:each) do
    ImportClass1.columns.clear
  end

  it "should store translation options" do
    ImportClass1.column "Name"
    ImportClass1.column "Age", :type => Integer
    ImportClass1.translate_to DummyClass.name

    ImportClass1.translated_class.should == DummyClass
  end


  it "should translate all rows" do
    ImportClass1.column "Name"
    ImportClass1.column "Age", :type => Integer
    ImportClass1.translate_to DummyClass.name

    ImportClass1.import(@xls_file)

    dummy_objects = ImportClass1.translate_all

    rows = [
      {"Name" => "Foo", "Age" => 27}, # First row
      {"Name" => "Bar", "Age" => 42}, # Second row
      {"Name"=>"Blue", "Age"=>28}, # Third row
      {"Name" => nil, "Age" => 25} # Fourth row
    ]

    check_rows rows, dummy_objects

  end


  it "should translate only valid rows when required" do
    ImportClass1.column "Name", :validate_presence => true
    ImportClass1.column "Age", :type => Integer
    ImportClass1.translate_to DummyClass.name

    ImportClass1.import(@xls_file)

    dummy_objects = ImportClass1.translate_valid

    rows = [
      {"Name" => "Foo", "Age" => 27}, # First row
      {"Name" => "Bar", "Age" => 42}, # Second row
      {"Name"=>"Blue", "Age"=>28}, # Third row
    ]

    check_rows rows, dummy_objects

  end


  it "should translate only valid rows when required" do
    ImportClass1.column "Name", :validate_presence => true
    ImportClass1.column "Age", :type => Integer
    ImportClass1.translate_to DummyClass.name

    ImportClass1.import(@xls_file)

    dummy_objects = ImportClass1.translate_invalid

    rows = [
      {"Name" => nil, "Age" => 25} # Fourth row
    ]

    check_rows rows, dummy_objects

  end


  it "should translate fields using the :field parameter" do
    ImportClass1.column "Rank", :translation => :name
    ImportClass1.column "Age", :type => Integer
    ImportClass1.translate_to DummyClass.name

    ImportClass1.import(@xls_file)

    dummy_objects = ImportClass1.translate_all

    rows = [
      {"Name" => 1, "Age" => 27}, # First row
      {"Name" => 2, "Age" => 42}, # Second row
      {"Name"=>nil, "Age"=>28}, # Third row
      {"Name" => 3, "Age" => 25} # Fourth row
    ]

    check_rows rows, dummy_objects

  end


end

def check_rows rows, objects

    objects.length.should == rows.count

    objects.each_with_index do |dummy_object, i|
      rows[i].each do |name, value|
        dummy_object.send(name.downcase).should == value
      end
    end
end