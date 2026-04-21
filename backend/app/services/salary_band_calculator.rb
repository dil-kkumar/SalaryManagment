# frozen_string_literal: true

class SalaryBandCalculator
  def self.calculate_bands(num_bands = 4)
    new.call(num_bands)
  end

  def call(num_bands = 4)
    salaries = Employee.order(:salary).pluck(:salary)
    return [] if salaries.empty?

    # Calculate percentile boundaries
    boundaries = (1...num_bands).map do |i|
      index = (i * salaries.length / num_bands) - 1
      salaries[[index, 0].max]
    end

    bands = []
    min_sal = salaries.first
    max_sal = salaries.last

    # Build bands with boundaries
    boundaries_with_min_max = [min_sal] + boundaries + [max_sal]

    (0...boundaries_with_min_max.length - 1).each do |i|
      lower = boundaries_with_min_max[i]
      upper = boundaries_with_min_max[i + 1]

      bands << {
        label: format_band_label(lower, upper),
        lower: lower,
        upper: upper
      }
    end

    bands
  end

  private

  def format_band_label(lower, upper)
    "$#{format_currency(lower)} – $#{format_currency(upper)}"
  end

  def format_currency(amount)
    case amount
    when 1_000_000..Float::INFINITY
      "#{(amount / 1_000_000).round(1)}M"
    when 1_000..Float::INFINITY
      "#{(amount / 1_000).round}k"
    else
      amount.to_s
    end
  end
end
