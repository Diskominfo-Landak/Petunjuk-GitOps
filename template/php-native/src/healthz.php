<?php
header('Content-Type: application/json');
http_response_code(200);

echo json_encode([
    'status' => 'ok',
    'php_version' => PHP_VERSION,
    'timestamp' => date('c')
]);
