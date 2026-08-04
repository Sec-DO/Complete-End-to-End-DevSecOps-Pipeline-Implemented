<?php
/**
 * SecDO - Secure Database Connection Handler
 * Uses environment variables for configuration to avoid hardcoded credentials.
 */

class Database {
    private string $host;
    private string $db_name;
    private string $username;
    private string $password;
    private int $port;
    public ?PDO $conn = null;

    public function __construct() {
        $this->host = getenv('DB_HOST') ?: 'db';
        $this->db_name = getenv('DB_NAME') ?: 'secdo_db';
        $this->username = getenv('DB_USER') ?: 'secdo_user';
        $this->password = getenv('DB_PASSWORD') ?: 'secdo_password';
        $this->port = (int)(getenv('DB_PORT') ?: 3306);
    }

    public function getConnection(): ?PDO {
        $this->conn = null;
        try {
            $dsn = "mysql:host=" . $this->host . ";port=" . $this->port . ";dbname=" . $this->db_name . ";charset=utf8mb4";
            $options = [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false,
            ];
            $this->conn = new PDO($dsn, $this->username, $this->password, $options);
        } catch (PDOException $exception) {
            error_log("Database Connection Error: " . $exception->getMessage());
        }
        return $this->conn;
    }
}
?>
