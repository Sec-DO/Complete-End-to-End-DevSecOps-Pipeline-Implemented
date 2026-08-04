-- SecDO Database Schema Setup
CREATE DATABASE IF NOT EXISTS secdo_db;
USE secdo_db;

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    email VARCHAR(100) NOT NULL,
    role VARCHAR(20) DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS audit_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    event_name VARCHAR(100) NOT NULL,
    severity VARCHAR(20) NOT NULL,
    details TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert Default Seed Data
INSERT INTO users (username, password_hash, email, role) 
VALUES ('admin', '$2y$10$e0MYzXyjpJS7Pd0RVvHwHe16.M.11.x2W/O7R92K9a', 'admin@secdo.internal', 'admin')
ON DUPLICATE KEY UPDATE username=username;
