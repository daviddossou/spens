# frozen_string_literal: true

# Amounts as people type them: "12,50", "1 250,50", "1.250,50" and "1,250.50"
# all become "1250.50" before the attribute casts, so the decimal type and the
# numericality validator (which reads the raw string) both see a plain number.
module AmountInput
  extend ActiveSupport::Concern

  class_methods do
    def amount_attributes(*names)
      names.each do |name|
        define_method(:"#{name}=") { |value| super(AmountInput.normalize(value)) }
      end
    end
  end

  # A lone separator followed by exactly three digits groups thousands ("1.250",
  # "1,250"); one or two digits, or four and more, are decimals ("12,50").
  def self.normalize(value)
    return value unless value.is_a?(String)

    str = value.gsub(/[[:space:]']/, "")
    return str unless str.match?(/[.,]/)

    if str.count(".").positive? && str.count(",").positive?
      decimal = str.rindex(".") > str.rindex(",") ? "." : ","
      str.delete(decimal == "." ? "," : ".").tr(",", ".")
    elsif str.count(".,") > 1 || str.match?(/[.,]\d{3}\z/)
      str.delete(".,")
    else
      str.tr(",", ".")
    end
  end
end
