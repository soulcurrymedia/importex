module Importex
  class Column
    attr_reader :name
    attr_accessor :errors
  
    def initialize(name, options = {})
      @name = name
      @type = options[:type]
      @format = [options[:format]].compact.flatten
      @required = options[:required]
      @validate_presence = options[:validate_presence]
    end
  
    def cell_value(str)
      @type ? @type.importex_value(str) : str
    end

    def validate_cell(value)
      self.errors = []
      # If we shoud validate presence and the str is empty, error
      self.errors << "can't be blank" if validate_presence? && value.to_s.empty? 

      # we try to get the importex_value of the field. If we have an exception, there's an error
      begin
        @type.importex_value(value) unless @type.nil?
      rescue InvalidCell => e
        self.errors << e.message
      end

      # we check the format of the cell
      if @format && !@format.empty? && !@format.any? { |format| match_format?(value, format) }
        self.errors << "format error: #{@format.reject { |r| r.kind_of? Proc }.inspect}"
      end      
    end

    def valid_cell?(value)
      validate_cell(value)
      self.errors.blank?
    end
    
    def match_format?(str, format)
      str = str.to_s
      case format
      when String then str == format
      when Regexp then str =~ format
      when Proc then format.call(str)
      end
    end
    
    def required?
      @required
    end

    def validate_presence?
      @validate_presence
    end

    # Translation logic in columns
    def translate object, row
      object.send("#{name.downcase}=", row.attributes[name])
      object
    end

  end
end
