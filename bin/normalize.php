<?php
require __DIR__ . '/functions.php';

$stdin  = fopen('php://stdin', 'r');
$stdout = fopen('php://stdout', 'wb+');

while (! feof($stdin)) {
    $string = fread($stdin, 4096);
    if (false === $string) {
        break;
    }
    fwrite($stdout, strtolower($string));
}

fclose($stdin);
fclose($stdout);
