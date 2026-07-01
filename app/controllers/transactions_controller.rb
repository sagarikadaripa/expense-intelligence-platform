# frozen_string_literal: true

class TransactionsController < ApplicationController
  before_action :authenticate_user!

  def index
    @transactions = current_user.transactions.expenses.recent.limit(50)
  end

  def create
    transaction = ManualTransactionService.new(current_user).create!(create_params)
    AuditLogger.log(user: current_user, action: "transaction.created", resource: transaction)
    redirect_to return_path, notice: "Transaction added."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to return_path, alert: e.record.errors.full_messages.to_sentence
  rescue ArgumentError, TypeError => e
    redirect_to return_path, alert: e.message
  end

  def destroy
    @transaction = current_user.transactions.find(params[:id])
    @transaction.destroy!
    AuditLogger.log(user: current_user, action: "transaction.deleted", resource: @transaction)
    redirect_to return_path, notice: "Transaction deleted."
  end

  def update
    @transaction = current_user.transactions.find(params[:id])
    ManualTransactionService.new(current_user).update!(@transaction, update_params)
    AuditLogger.log(user: current_user, action: "transaction.updated", resource: @transaction)
    redirect_to return_path, notice: "Transaction updated."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to return_path, alert: e.record.errors.full_messages.to_sentence
  rescue ArgumentError, TypeError => e
    redirect_to return_path, alert: e.message
  end

  private

  def return_path
    tab = params[:tab].presence_in(%w[overview transactions import insights]) || "transactions"
    path_params = { tab: tab }
    path_params[:page] = params[:page] if params[:page].present?
    path_params[:period] = params[:period] if params[:period].present?
    path_params.merge!(params.permit(TransactionFilterService::FILTER_KEYS).to_h.compact_blank)
    dashboard_path(path_params)
  end

  def create_params
    params.require(:transaction).permit(
      :amount, :merchant_name, :description, :category_id,
      :payment_method, :transaction_at
    )
  end

  def update_params
    params.require(:transaction).permit(
      :category_id, :amount, :description, :merchant_name,
      :payment_method, :transaction_at
    )
  end
end
