# Spens

A personal finance app built with Rails 8. Track income, expenses, debts, and savings goals across multiple workspaces — with built-in analytics and bilingual support (English & French).

**Live at [spens.me](https://spens.me)**

---

## Features

### Passwordless Authentication
Sign up with your name and email. Log in with a 6-digit OTP code sent to your inbox — no passwords to remember. Codes expire after 10 minutes.

### Guided Onboarding
A 3-step wizard walks new users through setup:
1. **Financial goals** — pick what matters (save for emergencies, pay off debt, track spending, etc.)
2. **Profile** — choose your country and currency, set income frequency and source
3. **Accounts** — create your first accounts with opening balances

### Spaces (Multi-Workspace)
Create separate spaces for different contexts (personal, business, side project). Each space has its own currency, country, accounts, transactions, debts, and goals. Switch between them instantly.

### Accounts & Transactions
- Create unlimited accounts (checking, savings, cash, mobile money, etc.)
- Record income, expenses, and transfers between accounts
- Assign transaction types (groceries, rent, salary, freelance, etc.) — or create your own
- Balances update automatically
- Locale-aware suggestions for account names and transaction categories

### Savings Goals
Set a target amount on any account. Track progress with percentage indicators and visual progress bars.

### Debt Tracking
Log money you've lent or borrowed, with contact names. Track repayments over time. Linked transactions update debt totals automatically. Mark debts as paid when settled.

### Analytics Dashboard
Three tabs with interactive charts (Chart.js + Chartkick):
- **Income & Expenses** — totals, category breakdowns (doughnut), cash flow trend (line), top spending categories (bar)
- **Debts** — amounts owed to/by you, breakdowns by person, repayment trends
- **Savings** — total balance, distribution across accounts, goal progress, monthly saving trends

Filter by 9 time periods: today, yesterday, this week, this month, last 3/6/12 months, all time, or custom date range.

### Home Dashboard
Summary cards (total balance, saved this month, debts owed to you, debts you owe) plus a paginated transaction feed with infinite scroll via Turbo Streams.

### Bilingual (English & French)
URL-scoped locale (`/en/...`, `/fr/...`) with automatic detection from browser headers. All UI labels, account templates, and transaction type suggestions adapt to the user's language.

### Currency & Country Support
170+ currencies with priority on West/Central African currencies (XOF, XAF). Smart formatting with K/M/B abbreviations. ISO 3166 country list with regional priority.

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | Rails 8.0.3, Ruby 3.3.4 |
| Database | PostgreSQL 16 (UUID primary keys) |
| Frontend | Hotwire (Turbo + Stimulus), Tailwind CSS, Importmap |
| Components | ViewComponent |
| Charts | Chartkick + Chart.js + Groupdate |
| Auth | Devise (session management) + custom OTP flow |
| Background Jobs | Solid Queue (in-Puma), Sidekiq + Redis |
| Cache / Cable | Solid Cache, Solid Cable (PostgreSQL-backed) |
| Assets | Propshaft |
| Money | money-rails, countries gem |
| Email | Brevo SMTP |
| Testing | RSpec, FactoryBot, SimpleCov |
| Code Quality | RuboCop (Rails + RSpec cops), Brakeman |
| Deployment | Kamal 2, Docker, GHCR |

### Architecture Highlights

- **Form objects** (`BaseForm` + per-resource forms) encapsulate validation and persistence outside controllers
- **Service objects** for business logic (transaction creation, account/type lookup, currency/country services, suggestions)
- **ViewComponent** for all UI primitives (buttons, cards, stats, navigation, form fields)
- **Space-scoped multi-tenancy** via `SpaceScoping` concern — all queries filtered by active space
- **Onboarding gate** blocks access to the app until setup is complete

---

## Development

### Prerequisites

- Docker and Docker Compose
- ngrok account (optional, for tunneling)

### Setup

```bash
# Copy environment template
cp .env.example .env

# Run automated setup (builds containers, creates database, runs seeds)
./bin/docker-setup

# Start all services
./bin/docker-manage up
```

The app is available at http://localhost:3000.

### Essential Commands

| Command | Purpose |
|---------|---------|
| `./bin/docker-manage up` | Start all services |
| `./bin/docker-manage down` | Stop all services |
| `./bin/docker-manage console` | Rails console |
| `./bin/docker-manage test` | Run all tests |
| `./bin/docker-manage test spec/models/user_spec.rb` | Run specific test |
| `./bin/docker-manage rubocop` | Check code style |
| `./bin/docker-manage rubocop-fix` | Auto-fix style issues |
| `./bin/docker-manage logs` | View web logs |
| `./bin/docker-manage shell` | Container bash shell |
| `./bin/docker-manage migrate` | Run database migrations |
| `./bin/docker-manage reset` | Drop, create, migrate, seed database |
| `./bin/docker-manage build` | Rebuild Docker containers |
| `./bin/docker-manage clean` | Clean up containers and volumes |

### Testing

```bash
# Run all specs
./bin/docker-manage test

# Run a specific file or directory
./bin/docker-manage test spec/models/user_spec.rb
./bin/docker-manage test spec/controllers/

# Run a specific line
./bin/docker-manage test spec/models/user_spec.rb:25

# Verbose + fail-fast mode
./bin/docker-manage test-watch

# Full backtrace debugging
./bin/docker-manage test-debug
```

### Code Quality

```bash
# Check style
./bin/docker-manage rubocop

# Auto-fix safe issues
./bin/docker-manage rubocop-fix

# Auto-fix all issues (including unsafe — use with caution)
./bin/docker-manage rubocop-fix-all
```

---

## Deployment

Deployed to production with [Kamal 2](https://kamal-deploy.org/) using kamal-proxy for automatic SSL via Let's Encrypt.

### Production Architecture

- **Reverse proxy**: kamal-proxy (Let's Encrypt SSL)
- **App server**: Thruster → Puma (inside Docker)
- **Database**: PostgreSQL 16 (Kamal accessory on same server)
- **Jobs**: Solid Queue (runs inside Puma process)
- **Cache / Cable**: Solid Cache + Solid Cable (PostgreSQL-backed)
- **Registry**: GitHub Container Registry (ghcr.io)
- **Email**: Brevo SMTP

### Security

These files are **gitignored** and never committed:

| File | Purpose |
|------|---------|
| `config/credentials/production.key` | Decrypts production credentials |
| `config/credentials/development.key` | Decrypts development credentials |
| `config/master.key` | Global master key |

`.kamal/secrets` is committed but contains **no raw secrets** — it only reads from environment variables and the gitignored key file. Without the key and env vars, no one can deploy.

### Deploy Your Own Instance

If you fork this repo:

#### 1. Generate credentials

```bash
rm config/credentials/production.yml.enc
EDITOR="code --wait" bin/rails credentials:edit --environment production

# Add your SMTP credentials:
# brevo:
#   smtp_username: your-email@example.com
#   smtp_password: your-smtp-api-key
```

#### 2. Update `config/deploy.yml`

```yaml
image: ghcr.io/YOUR_GITHUB_USERNAME/spens

servers:
  web:
    - YOUR_SERVER_IP

proxy:
  ssl: true
  host: YOUR_DOMAIN

registry:
  server: ghcr.io
  username: YOUR_GITHUB_USERNAME

ssh:
  user: YOUR_SSH_USER

accessories:
  db:
    host: YOUR_SERVER_IP
```

#### 3. Create a GitHub Personal Access Token

Go to https://github.com/settings/tokens → classic token with scopes `write:packages`, `read:packages`, `delete:packages`. Set to **no expiration**.

#### 4. Set environment variables

```bash
# Add to ~/.zshrc or ~/.bashrc
export KAMAL_REGISTRY_PASSWORD="ghp_your_token_here"
export SPENS_DATABASE_PASSWORD="$(openssl rand -hex 32)"
```

#### 5. Configure DNS

Add an A record for your domain pointing to your server IP.

#### 6. Deploy

```bash
# First time (boots database + deploys app)
bin/kamal setup

# Subsequent deploys
bin/kamal deploy
```

### Kamal Commands

| Command | Purpose |
|---------|---------|
| `bin/kamal setup` | First-time deployment |
| `bin/kamal deploy` | Deploy latest code |
| `bin/kamal console` | Rails console on production |
| `bin/kamal shell` | Bash shell in production container |
| `bin/kamal logs` | Tail production logs |
| `bin/kamal dbc` | Database console |
| `bin/kamal app details` | Running container details |
| `bin/kamal accessory details db` | Database status |
| `bin/kamal accessory reboot db` | Restart database |
| `bin/kamal rollback VERSION` | Roll back to previous version |

---

## License

This project is open source.
