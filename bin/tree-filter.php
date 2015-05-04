<?php
require __DIR__ . '/functions.php';
$component        = $argv[1];
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

mkdir('.zend-migrate/src', 0777, true);
mkdir('.zend-migrate/test', 0777, true);

if (is_dir('library/Zend/' . $component)) {
    command(
        'rsync -a library/Zend/%s .zend-migrate/src/',
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
rename('.zend-migrate/src/' . $component, 'src');
rename('.zend-migrate/test/' . $component, 'test');
rmdir('.zend-migrate/src');
rmdir('.zend-migrate/test');
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
copy($assetDir . '/test-files/gitignore', 'test/.gitignore');
file_put_contents(
    'test/bootstrap.php',
    str_replace('{COMPONENT}', $normalized, file_get_contents($assetDir . '/test-files/bootstrap.php'))
);
exit(0);
