<?php
$component  = $argv[1];

$stdin  = fopen('php://stdin', 'r');
$stdout = fopen('php://stdout', 'wb+');
while (! feof($stdin)) {
    $string = fread($stdin, 4096);
    if (false === $string) {
        break;
    }
    fwrite($stdout, str_replace('{COMPONENT_NAME}', $component, $string));
}
fclose($stdin);
fclose($stdout);
