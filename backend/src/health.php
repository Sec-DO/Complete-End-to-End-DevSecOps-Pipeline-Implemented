<?php
/**
 * SecDO - Production Health Check Endpoint
 * Returns JSON status with HTTP 200 on success or HTTP 500 on failure.
 * Evaluates DB connectivity and PHP runtime health.
 */

header('Content-Type: application/json; charset=utf-8');

require_once __DIR__ . '/db.php';

$health = [
    'timestamp' => date('c'),
    'status' => 'UP',
    'service' => 'SecDO-Application',
    'version' => getenv('APP_VERSION') ?: '1.0.0',
    'checks' => [
        'php_version' => PHP_VERSION,
        'database' => 'UNKNOWN'
    ]
];

$http_code = 200;

try {
    $db = new Database();
    $conn = $db->getConnection();
    if ($conn) {
        $health['checks']['database'] = 'UP';
    } else {
        $health['checks']['database'] = 'DOWN';
        // Note: In development/demo, DB might be starting up; set status degraded
        $health['status'] = 'DEGRADED';
    }
} catch (Exception $e) {
    $health['checks']['database'] = 'DOWN';
    $health['status'] = 'DOWN';
    $health['error'] = $e->getMessage();
    $http_code = 500;
}

http_response_code($http_code);
echo json_encode($health, JSON_PRETTY_PRINT);
exit;
?>
