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

      # We store a Proc object for translation
      @translation = options[:translation]

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
