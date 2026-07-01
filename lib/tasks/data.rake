# frozen_string_literal: true

namespace :data do
  desc "Delete all transactions and import history for a user (EMAIL=...)"
  task clear_transactions: :environment do
    email = ENV.fetch("EMAIL", "sagarika@expense.local")
    user = User.find_by!(email: email)
    count = user.transactions.count
    user.transactions.destroy_all
    user.statement_imports.destroy_all
    puts "Deleted #{count} transactions and import history for #{email}"
  end
end
