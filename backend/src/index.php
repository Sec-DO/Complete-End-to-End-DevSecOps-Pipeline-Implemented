<?php
/**
 * SecDO - Automated DevSecOps Demonstration Web Application
 * Features OWASP Hardening Headers, Dynamic MariaDB Operations, Health Probes & Audit Logging.
 */

// OWASP Security Hardening Headers
header("X-Frame-Options: DENY");
header("X-Content-Type-Options: nosniff");
header("X-XSS-Protection: 1; mode=block");
header("Referrer-Policy: strict-origin-when-cross-origin");

require_once __DIR__ . '/db.php';

$conn = isset($pdo) ? $pdo : null;
$db_status = $conn ? '<span class="status-badge badge-up">Connected (MariaDB 11)</span>' : '<span class="status-badge badge-down">Disconnected / Initializing</span>';
$app_version = getenv('APP_VERSION') ?: '1.0.0';
$hostname = gethostname();
$message = "";

// Backend Form Handler: Register / Insert Audit Log Entry into MariaDB
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action'])) {
    if ($_POST['action'] === 'log_event' && $conn) {
        $event_type = trim($_POST['event_name'] ?? 'Pipeline Verification');
        $description = trim($_POST['details'] ?? 'Manual web application interaction test.');
        $ip_address = $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1';
        $user_agent = $_SERVER['HTTP_USER_AGENT'] ?? 'Unknown Browser';

        try {
            $stmt = $conn->prepare("INSERT INTO audit_logs (event_type, description, ip_address, user_agent) VALUES (:event_type, :description, :ip_address, :user_agent)");
            $stmt->execute([
                ':event_type' => $event_type,
                ':description' => $description,
                ':ip_address' => $ip_address,
                ':user_agent' => $user_agent
            ]);
            $message = '<div class="alert alert-success">✓ Event successfully written to MariaDB database!</div>';
        } catch (PDOException $e) {
            $message = '<div class="alert alert-danger">Error writing event: ' . htmlspecialchars($e->getMessage()) . '</div>';
        }
    }
}

// Fetch Audit Logs from MariaDB Backend
$audit_logs = [];
if ($conn) {
    try {
        $stmt = $conn->query("SELECT * FROM audit_logs ORDER BY id DESC LIMIT 5");
        $audit_logs = $stmt->fetchAll();
    } catch (PDOException $e) {
        // Table created via init.sql / db.php
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SecDO | Automated DevSecOps Cloud Application</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;600;700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg-primary: #0b0f19;
            --bg-card: rgba(23, 32, 54, 0.75);
            --border-color: rgba(255, 255, 255, 0.1);
            --accent-cyan: #00f2fe;
            --accent-blue: #4facfe;
            --text-primary: #f3f4f6;
            --text-secondary: #9ca3af;
            --success: #10b981;
            --danger: #ef4444;
            --warning: #f59e0b;
        }

        * { box-sizing: border-box; margin: 0; padding: 0; }

        body {
            font-family: 'Outfit', sans-serif;
            background: var(--bg-primary);
            background-image: 
                radial-gradient(at 0% 0%, rgba(79, 172, 254, 0.15) 0px, transparent 50%),
                radial-gradient(at 100% 100%, rgba(0, 242, 254, 0.1) 0px, transparent 50%);
            color: var(--text-primary);
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            align-items: center;
            padding: 3rem 1.5rem;
        }

        .container {
            max-width: 950px;
            width: 100%;
            background: var(--bg-card);
            backdrop-filter: blur(16px);
            border: 1px solid var(--border-color);
            border-radius: 20px;
            padding: 3rem;
            box-shadow: 0 20px 50px rgba(0, 0, 0, 0.5);
        }

        .header { text-align: center; margin-bottom: 2.5rem; }

        .badge {
            display: inline-block;
            padding: 0.4rem 1rem;
            background: rgba(0, 242, 254, 0.1);
            border: 1px solid rgba(0, 242, 254, 0.3);
            color: var(--accent-cyan);
            border-radius: 50px;
            font-size: 0.85rem;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 1px;
            margin-bottom: 1rem;
        }

        h1 {
            font-size: 2.5rem;
            font-weight: 700;
            background: linear-gradient(135deg, #ffffff 0%, var(--accent-cyan) 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            margin-bottom: 0.75rem;
        }

        p.subtitle { color: var(--text-secondary); font-size: 1.1rem; }

        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 1.5rem;
            margin-bottom: 2.5rem;
        }

        .card {
            background: rgba(255, 255, 255, 0.03);
            border: 1px solid var(--border-color);
            border-radius: 12px;
            padding: 1.5rem;
        }

        .card h3 {
            font-size: 0.85rem;
            color: var(--text-secondary);
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-bottom: 0.75rem;
        }

        .card .value {
            font-family: 'JetBrains Mono', monospace;
            font-size: 1.1rem;
            font-weight: 600;
        }

        .status-badge {
            display: inline-block;
            padding: 0.25rem 0.75rem;
            border-radius: 6px;
            font-size: 0.85rem;
            font-weight: 600;
        }

        .badge-up { background: rgba(16, 185, 129, 0.15); color: var(--success); border: 1px solid rgba(16, 185, 129, 0.3); }
        .badge-down { background: rgba(239, 68, 68, 0.15); color: var(--danger); border: 1px solid rgba(239, 68, 68, 0.3); }

        .section-box {
            background: rgba(0, 0, 0, 0.25);
            border: 1px solid var(--border-color);
            border-radius: 12px;
            padding: 1.75rem;
            margin-bottom: 2rem;
        }

        .section-box h2 {
            font-size: 1.2rem;
            color: var(--accent-cyan);
            margin-bottom: 1rem;
        }

        .form-group { margin-bottom: 1rem; }
        label { display: block; font-size: 0.9rem; color: var(--text-secondary); margin-bottom: 0.4rem; }
        input, select, textarea {
            width: 100%;
            padding: 0.75rem;
            background: rgba(255, 255, 255, 0.05);
            border: 1px solid var(--border-color);
            border-radius: 8px;
            color: var(--text-primary);
            font-family: inherit;
        }

        button {
            padding: 0.75rem 1.5rem;
            background: linear-gradient(135deg, var(--accent-blue) 0%, var(--accent-cyan) 100%);
            border: none;
            border-radius: 8px;
            color: #0b0f19;
            font-weight: 600;
            cursor: pointer;
            transition: opacity 0.2s ease;
        }

        button:hover { opacity: 0.9; }

        table { width: 100%; border-collapse: collapse; margin-top: 1rem; font-size: 0.9rem; }
        th, td { padding: 0.75rem; text-align: left; border-bottom: 1px solid var(--border-color); }
        th { color: var(--accent-cyan); font-weight: 600; }

        .alert { padding: 1rem; border-radius: 8px; margin-bottom: 1.5rem; font-size: 0.9rem; }
        .alert-success { background: rgba(16, 185, 129, 0.15); color: var(--success); border: 1px solid rgba(16, 185, 129, 0.3); }
        .alert-danger { background: rgba(239, 68, 68, 0.15); color: var(--danger); border: 1px solid rgba(239, 68, 68, 0.3); }

        .footer { text-align: center; color: var(--text-secondary); font-size: 0.85rem; margin-top: 1rem; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="badge">Enterprise DevSecOps Cloud Application</div>
            <h1>SecDO Production App</h1>
            <p class="subtitle">Automated CI/CD, SAST, DAST, & MariaDB Persistence</p>
        </div>

        <?php echo $message; ?>

        <div class="grid">
            <div class="card">
                <h3>Application Version</h3>
                <div class="value"><?php echo htmlspecialchars($app_version); ?></div>
            </div>
            <div class="card">
                <h3>Backend Database</h3>
                <div class="value"><?php echo $db_status; ?></div>
            </div>
            <div class="card">
                <h3>Container Instance ID</h3>
                <div class="value"><?php echo htmlspecialchars(substr($hostname, 0, 15)); ?></div>
            </div>
        </div>

        <!-- Interactive Backend Feature: MariaDB Persistence Test -->
        <div class="section-box">
            <h2>Interactive Backend Audit Logger (MariaDB Integration)</h2>
            <form method="POST">
                <input type="hidden" name="action" value="log_event">
                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1rem;">
                    <div class="form-group">
                        <label>Event Name</label>
                        <input type="text" name="event_name" value="Production Deployment Verification" required>
                    </div>
                    <div class="form-group">
                        <label>Severity Level</label>
                        <select name="severity">
                            <option value="INFO">INFO</option>
                            <option value="WARNING">WARNING</option>
                            <option value="CRITICAL">CRITICAL</option>
                        </select>
                    </div>
                </div>
                <div class="form-group">
                    <label>Event Description / Audit Details</label>
                    <input type="text" name="details" value="Pipeline execution test verifying frontend to backend MariaDB flow." required>
                </div>
                <button type="submit">Submit Event to Backend DB</button>
            </form>

            <?php if (!empty($audit_logs)): ?>
                <h3 style="margin-top: 1.5rem; font-size: 1rem; color: var(--text-primary);">Recent MariaDB Database Entries:</h3>
                <table>
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Timestamp</th>
                            <th>Event Type</th>
                            <th>Description</th>
                            <th>Client IP</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($audit_logs as $log): ?>
                            <tr>
                                <td><?php echo htmlspecialchars($log['id']); ?></td>
                                <td><?php echo htmlspecialchars($log['timestamp']); ?></td>
                                <td><?php echo htmlspecialchars($log['event_type']); ?></td>
                                <td><?php echo htmlspecialchars($log['description']); ?></td>
                                <td><span class="status-badge badge-up"><?php echo htmlspecialchars($log['ip_address']); ?></span></td>
                            </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            <?php endif; ?>
        </div>

        <div class="footer">
            SecDO Production Stack &bull; Backend: PHP 8.3 Apache + MariaDB 11 &bull; Monitored via Prometheus
        </div>
    </div>
</body>
</html>
