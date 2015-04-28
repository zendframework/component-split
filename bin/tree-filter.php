<?php
require __DIR__ . '/functions.php';
$component        = $argv[1];
$normalized       = normalizeComponentName($component);
$rootDir          = $argv[2];
$assetDir         = $rootDir . '/assets';
$scriptDir        = $rootDir . '/bin';
$tmpDir           = $rootDir . '/tmp';
$php              = $argv[3];
$readme           = $argv[4] === '(none)' ? null : $argv[4];
$travisYml        = $argv[5] === '(none)' ? null : $argv[5];
$phpCs            = $argv[6] === '(none)' ? null : $argv[6];
$testConfigDist   = $argv[7];
$testConfigTravis = $argv[8];
$phpUnitConfig    = $argv[9] === '(none)' ? null : $argv[9];

mkdir('.zend-migrate/src-tree', 0777, true);
mkdir('.zend-migrate/test', 0777, true);

if (is_dir('library/Zend/' . $component)) {
    command(
        'rsync -a library/Zend/%s .zend-migrate/src-tree/',
        $component,
        sprintf('Failed to sync src directory for component %s; aborting', $component)
    );
    if (is_dir('tests/Zend/' . $component)) {
        command(
            'rsync -a tests/Zend/%s .zend-migrate/test/',
            $component,
            sprintf('Failed to sync test directory for component %s; aborting', $component)
        );
    }
    if (is_dir('tests/ZendTest/' . $component)) {
        command(
            'rsync -a tests/ZendTest/%s .zend-migrate/test/',
            $component,
            sprintf('Failed to sync test directory for component %s; aborting', $component)
        );
    }
}

command('rm -Rf *', sprintf("Error removing root-level files for component %s", $component));
rename('.zend-migrate/src-tree/' . $component, 'src');
rename('.zend-migrate/test/', 'test');
rmdir('.zend-migrate/src-tree');
rmdir('.zend-migrate');

foreach (new DirectoryIterator('src') as $fileInfo) {
    if (! in_array($fileInfo->getExtension(), ['json', 'md'])) {
        continue;
    }
    rename($fileInfo->getPathName(), './' . $fileInfo->getBasename());
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
if ($travisYml && file_exists($travisYml)) {
    copy($travisYml, '.travis.yml');
} else {
    copy($assetDir . '/root-files/travis.yml', '.travis.yml');
}
if ($phpCs && file_exists($phpCs)) {
    copy($phpCs, '.php_cs');
} else {
    copy($assetDir . '/root-files/php_cs', '.php_cs');
}
if ($phpUnitConfig && file_exists($phpUnitConfig)) {
    copy($phpUnitConfig, 'phpunit.xml.dist');
} else {
    $phpUnitConfig = str_replace(
        '{COMPONENT}',
        $normalized,
        file_get_contents($assetDir . '/root-files/phpunit.xml.dist')
    );
    file_put_contents(
        'phpunit.xml.dist',
        str_replace('{COMPONENT_NAME}', $component, $phpUnitConfig)
    );
}
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
copy($assetDir . '/test-files/gitignore', 'test/.gitignore');
file_put_contents(
    'test/Bootstrap.php',
    str_replace('{COMPONENT}', $normalized, file_get_contents($assetDir . '/test-files/Bootstrap.php'))
);
copy($testConfigDist, 'test/TestConfiguration.php.dist');
copy($testConfigTravis, 'test/TestConfiguration.php.travis');
exit(0);
