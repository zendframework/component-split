<?php
require __DIR__ . '/functions.php';

$component  = $argv[1];
$normalized = normalizeComponentName($component);

$stdin  = fopen('php://stdin', 'r');
$stdout = fopen('php://stdout', 'wb+');
while (! feof($stdin)) {
    $string = fread($stdin, 4096);
    if (false === $string) {
        break;
    }
    fwrite($stdout, str_replace('{COMPONENT}', $normalized, $string));
}
fclose($stdin);
fclose($stdout);
