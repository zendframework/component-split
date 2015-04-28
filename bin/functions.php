<?php
function createComposerTemplate($component)
{
    $normalized = normalizeComponentName($component);
    return [
        'name'        => 'zendframework/zend-' . $normalized,
        'description' => 'Zend\\' . $component . ' component',
        'license'     => 'BSD-3-Clause',
        'keywords'    => ['zf2', $normalized],
        'autoload'    => ['psr-4' => []],
        'require'     => [
            'php' => '>=5.3.23',
        ],
        'require-dev' => [],
    ];
}

function normalizeComponentName($component)
{
    return strtolower(preg_replace('/([a-zA-Z])(?=[A-Z])/', '$1-', $component));
}

function arrayMergeRecursive(array $a, array $b, $preserveNumericKeys = false)
{
    foreach ($b as $key => $value) {
        if (isset($a[$key]) || array_key_exists($key, $a)) {
            if (!$preserveNumericKeys && is_int($key)) {
                $a[] = $value;
            } elseif (is_array($value) && is_array($a[$key])) {
                $a[$key] = arrayMergeRecursive($a[$key], $value, $preserveNumericKeys);
            } else {
                $a[$key] = $value;
            }
        } else {
            $a[$key] = $value;
        }
    }

    return $a;
}

function command($pattern, $errorMessage = null)
{
    $args = func_get_args();
    array_shift($args); // remove pattern
    if (! empty($args)) {
        $errorMessage = array_pop($args); // remove and re-assign error message
    }

    $command = vsprintf($pattern, $args);
    exec($command, $output, $status);
    if (0 != $status) {
        $errorMessage = empty($errorMessage)
            ? sprintf("Error executing command: %s\n", $command)
            : sprintf("%s\n    while executing command: %s\n", $errorMessage, $command);
        error_log($errorMessage);
        exit(1);
    }
}
