<?php
// SecDO - Application HealthProbe, Readiness & Prometheus Metrics Endpoint

$db_status_val = 0;
$db_status_str = 'DOWN';

try {
    @include_once 'db.php';
    if (isset($pdo) && $pdo !== null) {
        $stmt = $pdo->query("SELECT 1");
        if ($stmt !== false) {
            $db_status_val = 1;
            $db_status_str = 'UP';
        }
    }
} catch (Exception $e) {
    $db_status_val = 0;
    $db_status_str = 'DOWN';
}

// Return JSON format if requested specifically via ?format=json
if (isset($_GET['format']) && $_GET['format'] === 'json') {
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode([
        'timestamp' => date('c'),
        'status'    => 'UP',
        'service'   => 'SecDO-Application',
        'version'   => '1.0.0',
        'checks'    => [
            'php_version' => PHP_VERSION,
            'database'    => $db_status_str
        ]
    ], JSON_PRETTY_PRINT);
    exit;
}

// Default: Prometheus OpenMetrics Text Format (for Prometheus Telemetry Scraping)
header('Content-Type: text/plain; version=0.0.4; charset=utf-8');

echo "# HELP secdo_app_up Application health status (1 = UP, 0 = DOWN)\n";
echo "# TYPE secdo_app_up gauge\n";
echo "secdo_app_up 1\n\n";

echo "# HELP secdo_db_up MariaDB database connection status (1 = UP, 0 = DOWN)\n";
echo "# TYPE secdo_db_up gauge\n";
echo "secdo_db_up {$db_status_val}\n";
?>
