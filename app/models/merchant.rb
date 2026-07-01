# frozen_string_literal: true

class Merchant < ApplicationRecord
  has_many :transactions, dependent: :nullify

  validates :name, :normalized_name, presence: true
  validates :normalized_name, uniqueness: true

  before_validation :normalize

  def self.find_or_create_by_name!(name)
    normalized = normalize_name(name)
    return nil if normalized.blank?

    display_name = name.to_s.strip

    find_or_create_by!(normalized_name: normalized) do |merchant|
      merchant.name = display_name
    end
  rescue ActiveRecord::RecordNotUnique
    find_by!(normalized_name: normalized)
  end

  def self.normalize_name(name)
    name.to_s.strip.downcase.gsub(/\s+/, " ")
  end

  private

  def normalize
    self.normalized_name = self.class.normalize_name(name) if name.present?
    self.name = name.to_s.strip if name.present?
  end
end
