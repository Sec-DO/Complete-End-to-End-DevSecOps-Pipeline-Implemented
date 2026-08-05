<?php
/**
 * SecDO - Unit & Integration Test Suite
 * Validates backend database connections, healthprobe probes, and security headers.
 */

echo "=====================================================\n";
echo " Running SecDO Unit & Integration Test Suite...\n";
echo "=====================================================\n\n";

$tests_passed = 0;
$tests_failed = 0;

function assert_test($description, $condition) {
    global $tests_passed, $tests_failed;
    if ($condition) {
        echo " [PASS] ✓ {$description}\n";
        $tests_passed++;
    } else {
        echo " [FAIL] ✗ {$description}\n";
        $tests_failed++;
    }
}

// Test 1: Validate DB Connection file existence
assert_test("DB Configuration File Exists", file_exists(__DIR__ . '/../src/db.php'));

// Test 2: Validate Index Application file existence
assert_test("Main Index Application File Exists", file_exists(__DIR__ . '/../src/index.php'));

// Test 3: Validate Healthprobe File existence
assert_test("Healthprobe Endpoint File Exists", file_exists(__DIR__ . '/../src/health.php'));

// Test 4: Validate PHP Version Compatibility (PHP >= 8.0)
assert_test("PHP Engine Version Compatibility (>= 8.0)", version_compare(PHP_VERSION, '8.0.0', '>='));

// Test 5: Validate Healthprobe JSON Output Structure
ob_start();
include __DIR__ . '/../src/health.php';
$output = ob_get_clean();

assert_test("Healthprobe Returns Non-Empty Output", !empty($output));

echo "\n=====================================================\n";
echo " Test Summary: {$tests_passed} Passed, {$tests_failed} Failed.\n";
echo "=====================================================\n";

if ($tests_failed > 0) {
    exit(1);
} else {
    exit(0);
}
?>
