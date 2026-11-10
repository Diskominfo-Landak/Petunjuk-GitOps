<?php
// Template Starter PHP Native - Pemkab Landak
header('Content-Type: text/html; charset=UTF-8');

$appName = getenv('APP_NAME') ?: 'Aplikasi PHP Native Pemkab Landak';
$dbHost = getenv('DB_HOST') ?: 'db';
$dbName = getenv('DB_DATABASE') ?: 'app_db';
$dbUser = getenv('DB_USERNAME') ?: 'app_user';
$dbPass = getenv('DB_PASSWORD') ?: '';

$dbStatus = 'Belum diuji';
$dbError = '';

if ($dbHost && $dbName && $dbUser) {
    try {
        $pdo = new PDO("mysql:host={$dbHost};dbname={$dbName};charset=utf8mb4", $dbUser, $dbPass, [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_TIMEOUT => 3
        ]);
        $dbStatus = 'Terhubung Sukses ✅';
    } catch (Exception $e) {
        $dbStatus = 'Gagal Terhubung ❌';
        $dbError = $e->getMessage();
    }
}
?>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= htmlspecialchars($appName) ?></title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #f8fafc; color: #1e293b; padding: 40px 20px; margin: 0; }
        .card { max-width: 600px; margin: 0 auto; background: white; padding: 32px; border-radius: 12px; box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1); }
        h1 { margin-top: 0; color: #0f172a; font-size: 24px; }
        .badge { display: inline-block; padding: 4px 10px; border-radius: 6px; font-size: 13px; font-weight: 600; background: #e2e8f0; }
        .table { width: 100%; border-collapse: collapse; margin-top: 20px; font-size: 14px; }
        .table td { padding: 10px 0; border-bottom: 1px solid #f1f5f9; }
        .table td:first-child { color: #64748b; font-weight: 500; width: 40%; }
        .footer { margin-top: 24px; font-size: 12px; color: #94a3b8; text-align: center; }
    </style>
</head>
<body>
    <div class="card">
        <span class="badge">Standard GitOps Pemkab Landak</span>
        <h1><?= htmlspecialchars($appName) ?></h1>
        <p>Aplikasi PHP Native berjalan di atas arsitektur kontainer Docker.</p>
        
        <table class="table">
            <tr>
                <td>Versi PHP Runtime</td>
                <td><strong><?= PHP_VERSION ?></strong></td>
            </tr>
            <tr>
                <td>Status Koneksi Database</td>
                <td><strong><?= htmlspecialchars($dbStatus) ?></strong></td>
            </tr>
            <?php if ($dbError): ?>
            <tr>
                <td>Detail Error Database</td>
                <td style="color: #ef4444; font-size: 12px;"><?= htmlspecialchars($dbError) ?></td>
            </tr>
            <?php endif; ?>
            <tr>
                <td>Server Time</td>
                <td><?= date('Y-m-d H:i:s T') ?></td>
            </tr>
            <tr>
                <td>Pemeriksaan Kesehatan</td>
                <td><a href="/healthz.php">/healthz.php</a></td>
            </tr>
        </table>

        <div class="footer">
            Diskominfo Kabupaten Landak &bull; Bidang Aplikasi &amp; Tata Kelola SPBE
        </div>
    </div>
</body>
</html>
