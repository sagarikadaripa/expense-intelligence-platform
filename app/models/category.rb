# frozen_string_literal: true

class Category < ApplicationRecord
  belongs_to :user, optional: true
  has_many :transactions, dependent: :nullify
  has_many :budgets, dependent: :destroy

  validates :name, :slug, presence: true
  validates :slug, uniqueness: { scope: :user_id }

  before_validation :generate_slug

  scope :system_categories, -> { where(system: true) }
  scope :for_user, ->(user) { where(user_id: [nil, user.id]) }

  SYSTEM_CATEGORY_NAMES = {
    "transport" => "Transport/Travel",
    "health_fitness" => "Health/Fitness"
  }.freeze

  def self.system_category_name(slug)
    SYSTEM_CATEGORY_NAMES[slug] || slug.titleize
  end

  private

  def generate_slug
    self.slug = name.to_s.parameterize if name.present? && slug.blank?
  end
end
