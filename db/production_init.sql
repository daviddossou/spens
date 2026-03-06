-- Additional databases for Solid Cache, Solid Queue, and Solid Cable.
-- The primary database (spens_production) is created automatically by
-- the POSTGRES_DB environment variable.

CREATE DATABASE spens_production_cache;
CREATE DATABASE spens_production_queue;
CREATE DATABASE spens_production_cable;
