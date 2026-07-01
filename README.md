# Expense Intelligence Platform

A personal finance platform for tracking UPI and manual expenses, importing PhonePe/Google Pay statements, and surfacing spending insights through a multi-agent architecture.

## Features

### Dashboard

Four tabs in the web UI:

| Tab | Description |
|-----|-------------|
| **Overview** | Spending summary with day/week/month/year/all filters, Chart.js breakdowns (category, daily trend, payment method, top merchants), CSV/PDF export |
| **Transactions** | Paginated expense list with inline category editing, manual add, and delete |
| **Import** | Upload a standard CSV or Google Pay / PhonePe PDF with background processing and live progress |
| **Insights** | AI-generated anomalies, forecasts, and recommendations |

### Data ingestion

- **Statement import** — standard CSV (`date`, `description`, `amount`) or Google Pay / PhonePe PDF via the Import tab
- **Manual transactions** — add cash/card/UPI expenses from the Transactions tab
- **UPI API** — programmatic ingestion via `POST /api/v1/upi_transactions`
- **WhatsApp bot** — natural language expense logging and commands via webhook

### Categorization

Rule-based auto-categorization for common Indian merchants:

| Category | Examples |
|----------|----------|
| Food | Swiggy, Zomato, Swish, Bistro, Domino's |
| Groceries | Zepto, Blinkit, Instamart, BigBasket |
| Shopping | Amazon, Flipkart, Myntra, Ajio, Nykaa, Meesho |
| Transport/Travel | Uber, Rapido, Ola, BMRCL, Cleartrip, Goibibo, MakeMyTrip, ixigo, IndiGo, Air India |
| Health/Fitness | Cult, Cult.fit |
| Entertainment | YouTube, JioHotstar, Netflix, Spotify, District, BookMyShow, music |
| Rent | Rent, housing, landlord, lease |
| Other | Default fallback |

Low-confidence categorizations can be routed through human-in-the-loop approval.

### Other

- **Notifications** — daily/weekly/monthly summaries, budget alerts, anomaly alerts
- **Profile** — update name, email, phone, and preferred currency

## Architecture

Built with **Clean Architecture**, **DDD**, and a **multi-agent orchestration layer**:

```
┌─────────────────────────────────────────────────────────┐
│                    Orchestrator                          │
├─────────────┬──────────────┬──────────────┬─────────────┤
│  Ingestion  │ Categorization│ Reconciliation│  Parsing   │
│  WhatsApp   │   Command    │  Analytics   │ Reporting  │
│  Insights   │  Forecasting │ Recommendation│ Notification│
└─────────────┴──────────────┴──────────────┴─────────────┘
```

Agents communicate via shared context and well-defined contracts. Pipelines are intent-driven — for example, UPI ingestion runs ingestion → reconciliation → categorization.

## Tech Stack

| Layer     | Technology                    |
|-----------|-------------------------------|
| Backend   | Ruby on Rails 8, PostgreSQL   |
| Jobs      | Sidekiq, Redis                |
| Frontend  | Hotwire, Tailwind CSS, Chart.js |
| AI        | LLM integration (OpenAI/mock) |

## Getting Started

### Prerequisites

- Ruby 3.3+
- PostgreSQL 16+
- Redis 7+
- Xcode Command Line Tools (for native gem compilation)

```bash
sudo xcodebuild -license   # if bundle install fails
```

### Setup

```bash
cd expense-intelligence-platform
cp .env.example .env
bundle install
bin/rails db:create db:migrate db:seed
bin/dev   # Rails + Tailwind + Sidekiq
```

Visit [http://localhost:3000](http://localhost:3000).

### Docker

```bash
docker compose up --build
```

### Your account (after seeding)

- **Email:** sagarika@expense.local
- **Password:** password123
- **WhatsApp:** +91 7091362239

## Data management

Clear all transactions and import history for the seeded user:

```bash
bin/rails data:clear_transactions
# or for another user:
EMAIL=you@example.com bin/rails data:clear_transactions
```

## API (v1)

| Method | Endpoint                    | Description              |
|--------|-----------------------------|--------------------------|
| POST   | `/api/v1/upi_transactions`  | Ingest UPI transaction   |
| POST   | `/api/v1/whatsapp/webhook`  | WhatsApp message webhook |
| GET    | `/api/v1/dashboard`         | Dashboard analytics JSON |

Authenticate with `Authorization: Bearer <user_id>` (session-based auth in browser).

### UPI Ingestion Example

```bash
curl -X POST http://localhost:3000/api/v1/upi_transactions \
  -H "Authorization: Bearer <user_id>" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 450,
    "description": "Swiggy order",
    "upi_reference": "UPI123456",
    "merchant_name": "Swiggy"
  }'
```

### WhatsApp Examples

Send to your configured webhook:

- `800 shopping`
- `2500 rent`
- `Spent today`
- `Remaining budget`

## Configuration

| Variable              | Description                          |
|-----------------------|--------------------------------------|
| `LLM_PROVIDER`        | `mock` or `openai`                   |
| `OPENAI_API_KEY`      | OpenAI API key                       |
| `WHATSAPP_PROVIDER`   | `mock` or production provider        |
| `REDIS_URL`           | Redis connection URL                 |

## Testing

```bash
bundle exec rspec
```

## Project Structure

```
app/
  domain/          # Value objects (MoneyValue, PhoneNormalizer)
  models/          # ActiveRecord models
  repositories/    # Data access layer
  services/        # Application services (import, dashboard, manual txn)
  events/          # Domain events
  jobs/            # Sidekiq background jobs
  controllers/     # HTTP layer (web + API v1)
lib/
  agents/          # Multi-agent orchestration
  categorization/  # Strategy pattern for categorization
  upi/             # CSV/PDF statement parsers
  llm/             # LLM provider abstraction
  whatsapp/        # WhatsApp client
```

## License

MIT
