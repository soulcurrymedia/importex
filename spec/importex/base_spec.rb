require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../fixtures/import_class1.rb')
require File.expand_path(File.dirname(__FILE__) + '/../fixtures/import_class2.rb')

describe Importex::Base do
  before(:each) do
    @xls_file = File.dirname(__FILE__) + '/../fixtures/simple.xls'
  end

  after(:each) do
    ImportClass1.columns.clear
  end

  it "should import simple excel doc" do
    ImportClass1.column "Name"
    ImportClass1.column "Age", :type => Integer
    ImportClass1.import(@xls_file)
    ImportClass1.all.map(&:attributes).should == [{"Name" => "Foo", "Age" => 27}, {"Name" => "Bar", "Age" => 42}, {"Name"=>"Blue", "Age"=>28}, {"Name" => "", "Age" => 25}]
  end

  it "should import only the column given and ignore others" do
    ImportClass1.column "Age", :type => Integer
    ImportClass1.column "Nothing"
    ImportClass1.import(@xls_file)
    ImportClass1.all.map(&:attributes).should == [{"Age" => 27}, {"Age" => 42}, {"Age" => 28}, {"Age" => 25}]
  end

  it "should add restrictions through an array of strings or regular expressions" do
    ImportClass1.column "Age", :format => ["foo", /bar/]
    ImportClass1.import(@xls_file)
    ImportClass1.invalid.count.should be_equal 4
    ImportClass1.invalid.first.errors[:age].should be_include('format error: ["foo", /bar/]')
  end

  it "should support a lambda as a requirement" do
    ImportClass1.column "Age", :format => lambda { |age| age.to_i < 30 }
    ImportClass1.import(@xls_file)

    ImportClass1.invalid.count.should be_equal 1
    ImportClass1.invalid.first.errors[:age].should be_include('format error: []')

  end

  it "should have some default requirements" do
    ImportClass1.column "Name", :type => Integer
    ImportClass1.import(@xls_file)

    ImportClass1.invalid.count.should be_equal 3
    ImportClass1.invalid.first.errors[:name].should be_include('Not an Integer.')

  end

  it "should have a [] method which returns attributes" do
    simple = ImportClass1.new("Foo" => "Bar")
    simple["Foo"].should == "Bar"
  end

  it "should import if it matches one of the requirements given in array" do
    ImportClass1.column "Age", :type => Integer, :format => ["", /^[.\d]+$/]
    ImportClass1.import(@xls_file)
    ImportClass1.all.map(&:attributes).should == [{"Age" => 27}, {"Age" => 42}, {"Age" => 28}, {"Age" => 25}]
  end

  it "should raise an exception if required column is missing" do
    ImportClass1.column "Age", :required => true
    ImportClass1.column "Foo", :required => true
    lambda {
      ImportClass1.import(@xls_file)
    }.should raise_error(Importex::MissingColumn, "Columns 'Foo' is/are required but it doesn't exist in 'Name', 'Age', 'Rank'.")
  end

  it "should raise an exception if required value is missing" do
    ImportClass1.column "Rank", :validate_presence => true
    ImportClass1.import(@xls_file)

    ImportClass1.invalid.count.should be_equal 1
    ImportClass1.invalid.first.errors[:rank].should be_include('can\'t be blank')

  end

  it "should import different classes with different settings " do
    ImportClass1.column "Name"
    ImportClass1.column "Age", :type => Integer

    ImportClass2.column "Name", :validate_presence => true
    ImportClass2.column "Rank", :type => Integer


    ImportClass1.import(@xls_file)
    ImportClass2.import(@xls_file)

    ImportClass1.valid.map(&:attributes).should == [{"Name" => "Foo", "Age" => 27}, {"Name" => "Bar", "Age" => 42}, {"Name"=>"Blue", "Age"=>28}, {"Name" => "", "Age" => 25}]

    ImportClass2.valid.map(&:attributes).should == [{"Name" => "Foo", "Rank" => 1}, {"Name" => "Bar", "Rank" => 2}, {"Name" => "Blue", "Rank" => nil}]
  end

  it "should validate rows when all of them have been imported" do
    ImportClass1.column "Name"
    ImportClass1.column "Age", :type => Integer

    # We create a validation method for the class
    class ImportClass1
      def self.validate_all
        average_age = @records.map{|r| r["Age"]}.inject(&:+).to_f/@records.length
        @records.select{|r| r["Age"] > average_age + 10}.each do |r|
          r.errors[:age] ||= []
          r.errors[:age] << "Too old"
        end
        @records
      end
    end

    ImportClass1.import(@xls_file)
    ImportClass1.all.map(&:attributes).should eql([{"Name" => "Foo", "Age" => 27}, {"Name" => "Bar", "Age" => 42}, {"Name"=>"Blue", "Age"=>28}, {"Name" => "", "Age" => 25}])
    ImportClass1.valid.map(&:attributes).should eql([{"Name" => "Foo", "Age" => 27}, {"Name"=>"Blue", "Age"=>28}, {"Name" => "", "Age" => 25}])
    ImportClass1.invalid.map(&:attributes).should eql([{"Name" => "Bar", "Age" => 42}])

    # We restore the class to its previous state so other tests are not affected
    class ImportClass1
      def self.validate_all
        @records
      end
    end

  end

  it "should perform custom validations" do
    ImportClass1.column "Name"
    ImportClass1.column "Age", :type => Integer, :validate => [Proc.new { |v, row| ["Too old"] if v > 30}]

    ImportClass1.import(@xls_file)

    ImportClass1.valid.map(&:attributes).should  be_eql([{"Name" => "Foo", "Age" => 27}, {"Name" =>"Blue", "Age"=>28}, {"Name" => "", "Age" => 25}])
    ImportClass1.invalid.map(&:attributes).should  be_eql([{"Name" => "Bar"}])

    ImportClass1.invalid.first.errors[:age].should be_eql(["Too old"])

  end

  it "should take context on custom validations" do

    ImportClass1.send :define_method, :never_old? do
      self["Name"] == "Bar"
    end

    ImportClass1.column "Name"
    ImportClass1.column "Age", :type => Integer, :validate => [Proc.new { |v, row| ["Too old"] if v > 30 && !row.never_old?}]

    ImportClass1.import(@xls_file)

    ImportClass1.valid.map(&:attributes).should  be_eql([{"Name" => "Foo", "Age" => 27}, {"Name" => "Bar", "Age" => 42}, {"Name" =>"Blue", "Age"=>28}, {"Name" => "", "Age" => 25}])
    ImportClass1.invalid.map(&:attributes).should  be_empty

  end


end
