<?php // @codingStandardsIgnoreFile
if ($argc < 2) {
    echo "Missing component argument!";
    exit(1);
}

$component    = $argv[1];
$composerJson = getcwd() . '/composer.json';

if (! file_exists($composerJson)) {
    $composer = createComposerTemplate($component);
} else {
    $composer = json_decode(file_get_contents($composerJson), true);
}

// Reset homepage
$composer['homepage'] = 'https://github.com/zendframework/zend-' . normalizeComponentName($component);

// Rewrite PSR-0 to PSR-4
if (isset($composer['autoload']['psr-0'])) {
    $composer['autoload']['psr-4'] = $composer['autoload']['psr-0'];
    unset($composer['autoload']['psr-0']);
}

foreach ($composer['autoload']['psr-4'] as $componentName => $path) {
    $composer['autoload']['psr-4'][$componentName] = 'src/';
}

$composer['autoload-dev'] = [
    'psr-4' => [
        'ZendTest\\' . $component . '\\' => 'test/' . $component . '/',
    ],
];

if (! isset($composer['require-dev'])) {
    $composer['require-dev'] = [];
}

$composer['require-dev'] = array_merge($composer['require-dev'], [
    'fabpot/php-cs-fixer' => '~1.0',
    'satooshi/php-coveralls' => 'dev-master',
    'phpunit/PHPUnit' => '~4.0',
    'phpunit/phpcov' => '~2.0',
]);

file_put_contents($composerJson, json_encode(
    $composer,
    JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES
));

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
