# frozen_string_literal: true

module PhoneNormalizer
  module_function

  def normalize(number)
    digits = number.to_s.gsub(/\D/, "")
    return "+#{digits}" if digits.start_with?("91") && digits.length == 12
    return "+91#{digits}" if digits.length == 10

    "+#{digits}"
  end
end
