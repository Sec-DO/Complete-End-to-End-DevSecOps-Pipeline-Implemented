<?php
// SecDO - Application HealthProbe & Readiness Endpoint
header('Content-Type: application/json; charset=utf-8');

$status = 'UP';
$db_status = 'DOWN';

try {
    @include_once 'db.php';
    if (isset($pdo) && $pdo !== null) {
        $stmt = $pdo->query("SELECT 1");
        if ($stmt !== false) {
            $db_status = 'UP';
        }
    }
} catch (Exception $e) {
    $db_status = 'DOWN';
}

$response = [
    'timestamp' => date('c'),
    'status'    => $status,
    'service'   => 'SecDO-Application',
    'version'   => '1.0.0',
    'checks'    => [
        'php_version' => PHP_VERSION,
        'database'    => $db_status
    ]
];

http_response_code(200);
echo json_encode($response, JSON_PRETTY_PRINT);
?>
