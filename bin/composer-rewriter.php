<?php // @codingStandardsIgnoreFile
require __DIR__ . '/functions.php';

stream_set_blocking(STDIN, 1);
$component = $argv[1];
$current   = parseComposerJson($argv[2], $component, false);
$composer  = false;
$json      = '';
$composer  = arrayMergeRecursive($current, parseComposerJson('php://stdin', $component));

// Reset homepage
$composer['homepage'] = 'https://github.com/zendframework/zend-' . normalizeComponentName($component);

// Rewrite PSR-0 to PSR-4
if (isset($composer['autoload']['psr-0'])) {
    $composer['autoload']['psr-4'] = $composer['autoload']['psr-0'];
    unset($composer['autoload']['psr-0']);
}

// Ensure we have a PSR-4 autoload section
if (! isset($composer['autoload']['psr-4']) || empty($composer['autoload']['psr-4'])) {
    $composer['autoload']['psr-4'] = [
        'Zend\\' . $component . '\\' => 'src/',
    ];
}

// Rewrite rules to point to src/
foreach ($composer['autoload']['psr-4'] as $componentName => $path) {
    // Rules pointing to tests should be removed
    if (strstr($path, 'tests')) {
        unset($composer['autoload']['psr-4'][$componentName]);
        continue;
    }
    $composer['autoload']['psr-4'][$componentName] = 'src/';
}

// Setup development autoloading rules
$composer['autoload-dev'] = [
    'psr-4' => [
        'ZendTest\\' . $component . '\\' => 'test/',
    ],
];

// Create the require-dev section, if not present
if (! isset($composer['require-dev'])) {
    $composer['require-dev'] = [];
}

// Seed the require-dev section with QA tools
$composer['require-dev'] = array_merge($composer['require-dev'], [
    'fabpot/php-cs-fixer' => '1.7.*',
    'satooshi/php-coveralls' => 'dev-master',
    'phpunit/PHPUnit' => '~4.0',
]);

// Remove target-dir if present (deprecated, and obsoleted by having PSR-4 
// autoloading present)
if (isset($composer['target-dir'])) {
    unset($composer['target-dir']);
}

// Emit the new JSON
fwrite(STDOUT, json_encode(
    $composer,
    JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES
));

function parseComposerJson($path, $component, $useTemplateOnError = true)
{
    $json = file_get_contents($path);

    if (empty($json)) {
        if ($useTemplateOnError) {
            error_log(sprintf("\nNo composer.json contents for component %s at path %s; using template\n", $component, $path));
        }

        return $useTemplateOnError ? createComposerTemplate($component) : [];
    }

    $composer = json_decode($json, true);

    if (! is_array($composer)) {
        if ($useTemplateOnError) {
            error_log(sprintf("\nError decoding composer.json contents for component %s; using template\n", $component));
            error_log(sprintf("composer.json contents:\n%s\n", $json));
            error_log(sprintf("Parsed:\n%s\n", var_export($composer, 1)));
        }
        return $useTemplateOnError ? createComposerTemplate($component) : [];
    }

    return $composer;
}
