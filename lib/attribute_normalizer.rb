module AttributeNormalizer

  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods

    def normalize_attributes(*attributes, &block)

      attributes.each do |attribute|

        klass = class << self; self end

        klass.send :define_method, "normalize_#{attribute}" do |value|
          value = value.strip if value.is_a?(String)
          normalized = block_given? && !value.blank? ? yield(value) : value
          normalized.blank? ? nil : normalized
        end

        klass.send :private, "normalize_#{attribute}"

        src = <<-end_src
          def #{attribute}
            val = super
            val.nil? ? val : self.class.send(:normalize_#{attribute}, val)
          end

          def #{attribute}=(#{attribute})
            super(self.class.send(:normalize_#{attribute}, #{attribute}))
          end
        end_src

        module_eval src, __FILE__, __LINE__
        
      end
      
    end
  end
end
