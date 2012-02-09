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

  it "should translate only valid rows when required" do
    ImportClass1.column "Name", :validate_presence => true
    ImportClass1.column "Age", :type => Integer
    ImportClass1.translate_to DummyClass.name

    ImportClass1.import(@xls_file)

    dummy_objects = ImportClass1.translate_valid

    attributes = [
      {"Name" => "Foo", "Age" => 27}, # First row
      {"Name" => "Bar", "Age" => 42}, # Second row
      {"Name"=>"Blue", "Age"=>28}, # Third row
    ]

    dummy_objects.length.should == 3

    dummy_objects.each_with_index do |dummy_object, i|
      attributes[i].each do |name, value|
        dummy_object.send(name.downcase).should == value
      end
    end


  end

  it "should translate only valid rows when required" do
        ImportClass1.column "Name", :validate_presence => true
    ImportClass1.column "Age", :type => Integer
    ImportClass1.translate_to DummyClass.name

    ImportClass1.import(@xls_file)

    dummy_objects = ImportClass1.translate_invalid

    attributes = [
      {"Name" => nil, "Age" => 25} # Fourth row
    ]

    dummy_objects.length.should == 1

    dummy_objects.each_with_index do |dummy_object, i|
      attributes[i].each do |name, value|
        dummy_object.send(name.downcase).should == value
      end
    end


  end


end