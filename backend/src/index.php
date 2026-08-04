<?php
/**
 * SecDO - Automated DevSecOps Demonstration Web Application
 * Includes OWASP Security Headers, DB Status Indicator, and App Metrics.
 */

// OWASP Security Hardening Headers
header("X-Frame-Options: DENY");
header("X-Content-Type-Options: nosniff");
header("X-XSS-Protection: 1; mode=block");
header("Referrer-Policy: strict-origin-when-cross-origin");
header("Content-Security-Policy: default-src 'self'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data:;");

require_once __DIR__ . '/db.php';

$db = new Database();
$conn = $db->getConnection();
$db_status = $conn ? '<span class="status-badge badge-up">Connected (MariaDB)</span>' : '<span class="status-badge badge-down">Disconnected / Initializing</span>';
$app_version = getenv('APP_VERSION') ?: '1.0.0';
$hostname = gethostname();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SecDO | Automated CI/CD & Security Compliance Pipeline</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;600;700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg-primary: #0b0f19;
            --bg-card: rgba(23, 32, 54, 0.7);
            --border-color: rgba(255, 255, 255, 0.1);
            --accent-cyan: #00f2fe;
            --accent-blue: #4facfe;
            --text-primary: #f3f4f6;
            --text-secondary: #9ca3af;
            --success: #10b981;
            --danger: #ef4444;
            --warning: #f59e0b;
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

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
            justify-content: center;
            padding: 2rem;
        }

        .container {
            max-width: 900px;
            width: 100%;
            background: var(--bg-card);
            backdrop-filter: blur(16px);
            border: 1px solid var(--border-color);
            border-radius: 20px;
            padding: 3rem;
            box-shadow: 0 20px 50px rgba(0, 0, 0, 0.5);
        }

        .header {
            text-align: center;
            margin-bottom: 2.5rem;
        }

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

        p.subtitle {
            color: var(--text-secondary);
            font-size: 1.1rem;
        }

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
            transition: transform 0.2s ease, border-color 0.2s ease;
        }

        .card:hover {
            transform: translateY(-4px);
            border-color: var(--accent-cyan);
        }

        .card h3 {
            font-size: 0.9rem;
            color: var(--text-secondary);
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-bottom: 0.75rem;
        }

        .card .value {
            font-family: 'JetBrains Mono', monospace;
            font-size: 1.1rem;
            font-weight: 600;
            color: var(--text-primary);
        }

        .status-badge {
            display: inline-block;
            padding: 0.25rem 0.75rem;
            border-radius: 6px;
            font-size: 0.85rem;
            font-weight: 600;
        }

        .badge-up {
            background: rgba(16, 185, 129, 0.15);
            color: var(--success);
            border: 1px solid rgba(16, 185, 129, 0.3);
        }

        .badge-down {
            background: rgba(239, 68, 68, 0.15);
            color: var(--danger);
            border: 1px solid rgba(239, 68, 68, 0.3);
        }

        .pipeline-status {
            background: rgba(0, 0, 0, 0.3);
            border: 1px solid var(--border-color);
            border-radius: 12px;
            padding: 1.5rem;
        }

        .pipeline-status h3 {
            margin-bottom: 1rem;
            font-size: 1.1rem;
            color: var(--accent-cyan);
        }

        .tags {
            display: flex;
            flex-wrap: wrap;
            gap: 0.5rem;
        }

        .tag {
            background: rgba(255, 255, 255, 0.05);
            border: 1px solid var(--border-color);
            padding: 0.4rem 0.8rem;
            border-radius: 6px;
            font-size: 0.85rem;
            color: var(--text-secondary);
        }

        .footer {
            text-align: center;
            margin-top: 2rem;
            color: var(--text-secondary);
            font-size: 0.85rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="badge">Enterprise DevSecOps Pipeline</div>
            <h1>SecDO Cloud Application</h1>
            <p class="subtitle">Automated CI/CD, SAST, Vulnerability Scanning & Production Monitoring</p>
        </div>

        <div class="grid">
            <div class="card">
                <h3>Application Version</h3>
                <div class="value"><?php echo htmlspecialchars($app_version); ?></div>
            </div>
            <div class="card">
                <h3>Database Engine</h3>
                <div class="value"><?php echo $db_status; ?></div>
            </div>
            <div class="card">
                <h3>Container Instance ID</h3>
                <div class="value"><?php echo htmlspecialchars(substr($hostname, 0, 15)); ?></div>
            </div>
        </div>

        <div class="pipeline-status">
            <h3>Active DevSecOps Security Checks</h3>
            <div class="tags">
                <span class="tag">✓ SonarQube SAST Passed</span>
                <span class="tag">✓ Trivy Filesystem Clean</span>
                <span class="tag">✓ Trivy Container Image Scanned</span>
                <span class="tag">✓ AWS ECR Keyless Authentication</span>
                <span class="tag">✓ Automated Healthprobe Active</span>
                <span class="tag">✓ Prometheus & cAdvisor Telemetry Enabled</span>
            </div>
        </div>

        <div class="footer">
            SecDO Production Pipeline &bull; Infrastructure Monitored via Prometheus & Grafana
        </div>
    </div>
</body>
</html>
