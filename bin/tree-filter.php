<?php
require __DIR__ . '/functions.php';
$component        = str_replace('/', '\\\\', $argv[1]);
$normalized       = normalizeComponentName($component);
$rootDir          = $argv[2];
$assetDir         = $rootDir . '/assets';
$scriptDir        = $rootDir . '/bin';
$tmpDir           = $rootDir . '/tmp';
$php              = $argv[3];
$phpUnitConfig    = $argv[4];
$phpUnitTravis    = $argv[5];
$readme           = $argv[6] === '(none)' ? null : $argv[6];
$travisYml        = $argv[7] === '(none)' ? null : $argv[7];
$phpCs            = $argv[8] === '(none)' ? null : $argv[8];

mkdir('.zend-migrate', 0777);

$componentPath = str_replace('\\', '/', $component);
$foundLibrary  = false;
$foundTests    = false;
if (is_dir('library/Zend/' . $componentPath)) {
    $foundLibrary = true;
    rename(sprintf('library/Zend/%s', $componentPath), '.zend-migrate/src');
    if (is_dir('tests/Zend/' . $componentPath)) {
        $foundTests = true;
        rename(sprintf('tests/Zend/%s', $componentPath), '.zend-migrate/test');
    }
    if (is_dir('tests/ZendTest/' . $componentPath)) {
        $foundTests = true;
        rename(sprintf('tests/ZendTest/%s', $componentPath), '.zend-migrate/test');
    }
}

command('rm -Rf *', sprintf("Error removing root-level files for component %s", $component));
if ($foundLibrary) {
    rename('.zend-migrate/src', './src');
}
if ($foundTests) {
    rename('.zend-migrate/test', './test');
}
removeDir('.zend-migrate');

if ($foundLibrary) {
    foreach (new DirectoryIterator('src') as $fileInfo) {
        if (! in_array($fileInfo->getExtension(), ['json', 'md'])) {
            continue;
        }
        rename($fileInfo->getPathName(), './' . $fileInfo->getBasename());
    }
}

// Root directory files
if ($readme && file_exists($readme)) {
    copy($readme, 'README.md');
} else {
    file_put_contents(
        'README.md',
        str_replace('{COMPONENT}', $normalized, file_get_contents($assetDir . '/root-files/README-COMPONENT.md'))
    );
}
copy($assetDir . '/root-files/LICENSE.txt', 'LICENSE.txt');
copy($assetDir . '/root-files/coveralls.yml', '.coveralls.yml');
copy($assetDir . '/root-files/gitattributes', '.gitattributes');
copy($assetDir . '/root-files/gitignore', '.gitignore');
file_put_contents(
    'CONTRIBUTING.md',
    str_replace('{COMPONENT}', $normalized, file_get_contents($assetDir . '/root-files/CONTRIBUTING.md'))
);
copy($travisYml, '.travis.yml');
copy($phpCs, '.php_cs');
copy($phpUnitConfig, 'phpunit.xml.dist');
copy($phpUnitTravis, 'phpunit.xml.travis');
if (file_exists('composer.json')) {
    rename('composer.json', 'composer.json.orig');
    command(
        'cat composer.json.orig | %s %s/composer-rewriter.php %s %s/composer.json > composer.json',
        $php,
        $scriptDir,
        $component,
        $tmpDir,
        'Error rewriting composer.json'
    );
    unlink('composer.json.orig');
} else {
    command(
        'echo -n | %s %s/composer-rewriter.php %s %s/composer.json > composer.json',
        $php,
        $scriptDir,
        $component,
        $tmpDir,
        'Error creating composer.json'
    );
}

// Test directory files
if (! $foundTests) {
    mkdir('test');
}
file_put_contents(
    'test/bootstrap.php',
    str_replace('{COMPONENT}', $normalized, file_get_contents($assetDir . '/test-files/bootstrap.php'))
);
exit(0);
