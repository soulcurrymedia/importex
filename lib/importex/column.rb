module Importex
  class Column
    attr_reader :name
  
    def initialize(name, options = {})
      @name = name
      @type = options[:type]
      @format = [options[:format]].compact.flatten
      @required = options[:required]
      @validate_presence = options[:validate_presence]
    end
  
    def cell_value(str, row_number)
      if validate_presence? && str.to_s.empty?
        raise InvalidCell, "(column #{name}, row #{row_number+1}) can't be blank"
      else
        begin
      validate_cell(str)
          (@type && (validate_presence? || !str.to_s.empty?)) ? @type.importex_value(str) : str
    rescue InvalidCell => e
      raise InvalidCell, "#{str} (column #{name}, row #{row_number+1}) does not match required format: #{e.message}"
        end
      end
    end
    
    def validate_cell(str)
      if @format && !@format.empty? && !@format.any? { |format| match_format?(str, format) }
        raise InvalidCell, @format.reject { |r| r.kind_of? Proc }.inspect
      end
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
  end
end
