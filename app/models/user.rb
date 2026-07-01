# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  has_many :upi_ids, dependent: :destroy
  has_many :transactions, dependent: :destroy
  has_many :categories, dependent: :destroy
  has_many :budgets, dependent: :destroy
  has_many :conversation_sessions, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :agent_tasks, dependent: :destroy
  has_many :audit_logs, dependent: :destroy
  has_many :insights, dependent: :destroy
  has_many :statement_imports, dependent: :destroy

  validates :name, :email, :mobile_number, :whatsapp_number, presence: true
  validates :email, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :whatsapp_number, uniqueness: true

  before_validation :normalize_phone_numbers
  before_validation :set_default_timezone, on: :create
  validates :preferred_currency, presence: true, inclusion: { in: %w[INR USD EUR GBP] }

  scope :onboarded, -> { where.not(onboarding_completed_at: nil) }

  def onboarding_complete?
    onboarding_completed_at.present?
  end

  def monthly_budget
    return nil unless monthly_budget_cents

    MoneyValue.new(monthly_budget_cents, preferred_currency)
  end

  def self.find_by_whatsapp(number)
    find_by(whatsapp_number: PhoneNormalizer.normalize(number))
  end

  def self.find_by_whatsapp!(number)
    find_by_whatsapp(number) || raise(ActiveRecord::RecordNotFound)
  end

  private

  def normalize_phone_numbers
    self.mobile_number = PhoneNormalizer.normalize(mobile_number) if mobile_number.present?
    self.whatsapp_number = PhoneNormalizer.normalize(whatsapp_number) if whatsapp_number.present?
  end

  def set_default_timezone
    self.timezone = "Asia/Kolkata" if timezone.blank?
  end
end
