# Spens

A Rails 8.0 application with comprehensive Docker setup including PostgreSQL, Redis, Sidekiq, and ngrok.

## 🚀 Quick Start with Docker

### Prerequisites
- Docker and Docker Compose
- ngrok account (for tunneling)

### Setup

1. **Clone and setup environment:**
   ```bash
   # Copy environment template
   cp .env.example .env

   # Edit .env and add your NGROK_AUTHTOKEN
   # Get token from: https://dashboard.ngrok.com/get-started/your-authtoken
   ```

2. **Run the automated setup:**
   ```bash
   ./bin/docker-setup
   ```

   This script will:
   - ✅ Build all Docker containers (web, sidekiq, database, redis)
   - ✅ Start PostgreSQL and Redis services
   - ✅ Create and migrate the database
   - ✅ Run database seeds
   - ✅ Display access URLs and next steps

3. **Start all services:**
   ```bash
   ./bin/docker-manage up
   ```

   **First time setup is now complete!** 🎉

## 🛠 Services

The application includes the following services:

- **Rails Web Server** (port 3000) - Main application
- **PostgreSQL** (port 5432) - Database
- **Redis** (port 6379) - Cache and job queue
- **Sidekiq** - Background job processor
- **ngrok** (port 4040) - Tunneling service for external access

## 📝 Docker Management Commands

We provide a convenient `./bin/docker-manage` script for all Docker operations:

### 🚀 **Starting & Stopping Services**
```bash
# Start all services (PostgreSQL, Redis, Rails, Sidekiq, ngrok)
./bin/docker-manage up

# Stop all services
./bin/docker-manage down

# Restart all services
./bin/docker-manage restart
```

### 📋 **Viewing Logs**
```bash
# View web server logs
./bin/docker-manage logs

# View Sidekiq logs
./bin/docker-manage logs sidekiq

# View database logs
./bin/docker-manage logs db

# View Redis logs
./bin/docker-manage logs redis
```

### 💻 **Development Tools**
```bash
# Open Rails console
./bin/docker-manage console

# Open bash shell in web container
./bin/docker-manage shell
```

### 🗄️ **Database Operations**
```bash
# Run database migrations
./bin/docker-manage migrate

# Seed the database
./bin/docker-manage seed

# Reset database (drop, create, migrate, seed)
./bin/docker-manage reset
```

### 🧪 **Running Tests**
```bash
# Run all tests
./bin/docker-manage test

# Run specific test file
./bin/docker-manage test spec/models/user_spec.rb

# Run all tests in a directory
./bin/docker-manage test spec/models

# Run specific test by line number
./bin/docker-manage test spec/models/user_spec.rb:25

# Run tests with detailed output and fail-fast
./bin/docker-manage test-watch

# Run tests with full debugging and backtrace
./bin/docker-manage test-debug
```

### 🛠️ **Container Management**
```bash
# Rebuild Docker containers
./bin/docker-manage build

# Clean up containers and volumes
./bin/docker-manage clean
```

### ℹ️ **Getting Help**
```bash
# Show all available commands
./bin/docker-manage
```

## 🌐 Access Points

- **Rails App**: http://localhost:3000
- **Sidekiq Dashboard**: http://localhost:3000/sidekiq
- **ngrok Web Interface**: http://localhost:4040
- **PostgreSQL**: localhost:5432 (user: postgres, password: password)
- **Redis**: localhost:6379

## 🎯 **Development Workflow**

### **Daily Development**
1. **Start your development environment:**
   ```bash
   ./bin/docker-manage up
   ```

2. **Open your application:**
   - Rails app: http://localhost:3000
   - Sidekiq dashboard: http://localhost:3000/sidekiq
   - ngrok public URL: Check http://localhost:4040

3. **Make code changes** (files are auto-reloaded)

4. **Run tests as you develop:**
   ```bash
   # Test the feature you're working on
   ./bin/docker-manage test spec/features/user_registration_spec.rb

   # Test related models
   ./bin/docker-manage test spec/models

   # Run all tests before committing
   ./bin/docker-manage test
   ```

5. **Database operations:**
   ```bash
   # Create new migration
   ./bin/docker-manage shell
   # Inside container: rails generate migration AddFieldToUsers field:string

   # Run the migration
   ./bin/docker-manage migrate
   ```

6. **Stop services when done:**
   ```bash
   ./bin/docker-manage down
   ```

### **Testing Strategies**

```bash
# 🧪 Test-Driven Development (TDD)
./bin/docker-manage test spec/models/user_spec.rb:25  # Run failing test
# Write code to make it pass
./bin/docker-manage test spec/models/user_spec.rb     # Verify it passes

# 🔍 Debugging failing tests
./bin/docker-manage test-debug spec/models/user_spec.rb

# 🚀 Quick feedback loop
./bin/docker-manage test-watch  # Detailed output with fail-fast
```

### **Troubleshooting**

```bash
# If containers are misbehaving
./bin/docker-manage clean
./bin/docker-setup  # Re-run setup

# View detailed logs
./bin/docker-manage logs web
./bin/docker-manage logs sidekiq

# Access Rails console for debugging
./bin/docker-manage console

# Access container shell for advanced debugging
./bin/docker-manage shell
```

## 🔧 **Technology Stack**

- **Framework**: Rails 8.0.3 with Ruby 3.3.4
- **Database**: PostgreSQL 15 with Solid gems (cache, queue, cable)
- **Background Jobs**: Sidekiq with Redis
- **Authentication**: Devise with comprehensive user management
- **Frontend**: Tailwind CSS + Hotwire (Turbo + Stimulus)
- **Testing**: RSpec, FactoryBot, SimpleCov
- **Code Quality**: Rubocop, Brakeman
- **Deployment**: Docker + Kamal ready
- **External Access**: ngrok tunneling

## 📚 **Quick Reference**

### **Essential Commands**
| Command | Purpose |
|---------|---------|
| `./bin/docker-setup` | First-time setup (run once) |
| `./bin/docker-manage up` | Start all services |
| `./bin/docker-manage down` | Stop all services |
| `./bin/docker-manage console` | Rails console |
| `./bin/docker-manage test` | Run all tests |
| `./bin/docker-manage test spec/models/user_spec.rb` | Run specific test |
| `./bin/docker-manage logs` | View web logs |
| `./bin/docker-manage shell` | Container bash shell |

### **URLs**
| Service | URL | Purpose |
|---------|-----|---------|
| Rails App | http://localhost:3000 | Main application |
| Sidekiq UI | http://localhost:3000/sidekiq | Background jobs |
| ngrok UI | http://localhost:4040 | Tunnel management |
| PostgreSQL | localhost:5432 | Database (user: postgres, pass: password) |
| Redis | localhost:6379 | Cache & job queue |

## 🚀 **Deployment**

This application is configured for deployment with Kamal and includes a production-ready Dockerfile.
