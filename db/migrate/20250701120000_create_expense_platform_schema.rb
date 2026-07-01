# frozen_string_literal: true

class CreateExpensePlatformSchema < ActiveRecord::Migration[8.1]
  def change
    enable_extension "pgcrypto" unless extension_enabled?("pgcrypto")

    create_table :users, id: :uuid do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :mobile_number, null: false
      t.string :whatsapp_number, null: false
      t.string :preferred_currency, null: false, default: "INR"
      t.string :timezone, null: false, default: "Asia/Kolkata"
      t.bigint :monthly_budget_cents
      t.string :password_digest, null: false
      t.boolean :whatsapp_verified, null: false, default: false
      t.datetime :onboarding_completed_at
      t.string :sync_token
      t.timestamps
    end
    add_index :users, :email, unique: true
    add_index :users, :whatsapp_number, unique: true
    add_index :users, :sync_token, unique: true

    create_table :upi_ids do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :upi_id, null: false
      t.boolean :primary, null: false, default: false
      t.datetime :verified_at
      t.timestamps
    end
    add_index :upi_ids, [:user_id, :upi_id], unique: true

    create_table :categories do |t|
      t.references :user, foreign_key: true, type: :uuid
      t.string :name, null: false
      t.string :slug, null: false
      t.string :icon
      t.boolean :system, null: false, default: false
      t.timestamps
    end
    add_index :categories, [:user_id, :slug], unique: true

    create_table :merchants do |t|
      t.string :name, null: false
      t.string :normalized_name, null: false
      t.timestamps
    end
    add_index :merchants, :normalized_name, unique: true

    create_table :transactions do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :category, foreign_key: true
      t.references :merchant, foreign_key: true
      t.bigint :amount_cents, null: false
      t.string :currency, null: false, default: "INR"
      t.string :payment_method, null: false, default: "upi"
      t.string :source, null: false, default: "upi"
      t.string :status, null: false, default: "completed"
      t.string :description
      t.datetime :transaction_at, null: false
      t.string :upi_reference
      t.string :external_id
      t.string :fingerprint
      t.jsonb :metadata, null: false, default: {}
      t.references :related_transaction, foreign_key: { to_table: :transactions }
      t.timestamps
    end
    add_index :transactions, [:user_id, :transaction_at]
    add_index :transactions, [:user_id, :fingerprint], unique: true, where: "fingerprint IS NOT NULL"
    add_index :transactions, :external_id
    add_index :transactions, :metadata, using: :gin

    create_table :conversation_sessions do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :channel, null: false, default: "whatsapp"
      t.string :state, null: false, default: "idle"
      t.jsonb :context, null: false, default: {}
      t.datetime :expires_at
      t.timestamps
    end
    add_index :conversation_sessions, [:user_id, :channel]

    create_table :conversation_messages do |t|
      t.references :conversation_session, null: false, foreign_key: true
      t.string :role, null: false
      t.text :content, null: false
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    create_table :budgets do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :category, foreign_key: true
      t.bigint :amount_cents, null: false
      t.string :period, null: false, default: "monthly"
      t.timestamps
    end
    add_index :budgets, [:user_id, :category_id, :period], unique: true

    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :notification_type, null: false
      t.string :channel, null: false, default: "whatsapp"
      t.string :status, null: false, default: "pending"
      t.string :title
      t.text :body
      t.jsonb :payload, null: false, default: {}
      t.datetime :scheduled_at
      t.datetime :sent_at
      t.timestamps
    end
    add_index :notifications, [:user_id, :status, :scheduled_at]

    create_table :agent_tasks do |t|
      t.references :user, foreign_key: true, type: :uuid
      t.string :agent_type, null: false
      t.string :status, null: false, default: "pending"
      t.jsonb :input, null: false, default: {}
      t.jsonb :output, null: false, default: {}
      t.jsonb :context, null: false, default: {}
      t.references :parent_task, foreign_key: { to_table: :agent_tasks }
      t.text :error_message
      t.timestamps
    end
    add_index :agent_tasks, [:user_id, :agent_type, :status]

    create_table :audit_logs do |t|
      t.references :user, foreign_key: true, type: :uuid
      t.string :action, null: false
      t.string :resource_type
      t.string :resource_id
      t.jsonb :metadata, null: false, default: {}
      t.string :ip_address
      t.timestamps
    end
    add_index :audit_logs, [:user_id, :created_at]

    create_table :insights do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :insight_type, null: false
      t.string :title, null: false
      t.text :body, null: false
      t.string :severity, null: false, default: "info"
      t.jsonb :metadata, null: false, default: {}
      t.datetime :dismissed_at
      t.timestamps
    end
    add_index :insights, [:user_id, :insight_type]

    create_table :active_storage_blobs do |t|
      t.string :key, null: false
      t.string :filename, null: false
      t.string :content_type
      t.text :metadata
      t.string :service_name, null: false
      t.bigint :byte_size, null: false
      t.string :checksum
      t.datetime :created_at, null: false
      t.index [:key], unique: true
    end

    create_table :active_storage_attachments do |t|
      t.string :name, null: false
      t.references :record, null: false, polymorphic: true, index: false
      t.references :blob, null: false, foreign_key: { to_table: :active_storage_blobs }
      t.datetime :created_at, null: false
      t.index [:record_type, :record_id, :name, :blob_id],
              name: :index_active_storage_attachments_uniqueness,
              unique: true
    end

    create_table :active_storage_variant_records do |t|
      t.references :blob, null: false, foreign_key: { to_table: :active_storage_blobs }, index: false
      t.string :variation_digest, null: false
      t.index [:blob_id, :variation_digest],
              name: :index_active_storage_variant_records_uniqueness,
              unique: true
    end

    create_table :statement_imports, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :status, null: false, default: "pending"
      t.string :source
      t.integer :total_count, null: false, default: 0
      t.integer :processed_count, null: false, default: 0
      t.integer :imported_count, null: false, default: 0
      t.text :error_message
      t.timestamps
    end
    add_index :statement_imports, [:user_id, :created_at]

    reversible do |dir|
      dir.up { seed_system_categories }
    end
  end

  private

  SYSTEM_CATEGORIES = {
    "food" => "Food",
    "groceries" => "Groceries",
    "transport" => "Transport/Travel",
    "shopping" => "Shopping",
    "rent" => "Rent",
    "utilities" => "Utilities",
    "entertainment" => "Entertainment",
    "health_fitness" => "Health/Fitness",
    "education" => "Education",
    "other" => "Other"
  }.freeze

  def seed_system_categories
    now = Time.current
    SYSTEM_CATEGORIES.each do |slug, name|
      execute <<~SQL.squish
        INSERT INTO categories (name, slug, system, created_at, updated_at)
        SELECT #{quote(name)}, #{quote(slug)}, TRUE, #{quote(now)}, #{quote(now)}
        WHERE NOT EXISTS (
          SELECT 1 FROM categories WHERE user_id IS NULL AND slug = #{quote(slug)}
        )
      SQL
    end
  end

  def quote(value)
    connection.quote(value)
  end
end
