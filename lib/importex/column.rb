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

      # We store an array of Proc objects for validation
      @validation = options[:validate].is_a?(Proc) ? [options[:validate]] : options[:validate]

      # We store a Proc object for translation
      @translation = options[:translation]
    end

    def cell_value(str, row_number)
      if validate_presence? && str.empty?
        raise InvalidCell, "(column #{name}, row #{row_number+1}) can't be blank"
      else
        begin
          validate_cell(str)
          (@type && (validate_presence? || !str.empty?)) ? @type.importex_value(str) : str
        rescue InvalidCell => e
          raise InvalidCell, "#{str} (column #{name}, row #{row_number+1}) does not match required format: #{e.message}"
        end
      end
    end

    def cell_value(str)
      @type ? @type.importex_value(str) : str
    end

    def validate_cell(value, row_context)
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

      if @validation
        validating_value = @type.nil? ? value : @type.importex_value(value)
        self.errors << @validation.map{|v| v.call validating_value, row_context}.compact
      end

      self.errors = self.errors.flatten
    end

    def valid_cell?(value, row_context)
      validate_cell(value, row_context)
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

      translation_proc = if @translation.nil?
        # If there's no translation we just transfer the field
          Proc.new { |o,r| direct_translation o,r}
        elsif @translation.is_a? Symbol
        # If translation is a symbol then it's a field's name so we just the attribute to that new field
          Proc.new { |o,r| field_translation o,r}
        elsif @translation.is_a? Proc
        # If it has its own logic, we just execute it
          @translation
        else
          Proc.new {}
      end

      translation_proc.call object, row
      object
    end

    private

    def direct_translation object, row
      value = row.attributes[name].to_s.empty? ? nil : row.attributes[name]
      object.send("#{name.downcase}=", value )
    end

    def field_translation object, row
      value = row.attributes[name].to_s.empty? ? nil : row.attributes[name]

      methods = @translation.to_s.split(".")
      attribute = methods.pop

      result = object
      methods.each{|m| result = result.send(m)}

      result.send("#{attribute}=", value)
    end


  end
end
