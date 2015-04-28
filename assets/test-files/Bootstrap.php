<?php
/**
 * @link      http://github.com/zendframework/zend-{COMPONENT} for the canonical source repository
 * @copyright Copyright (c) 2005-2015 Zend Technologies USA Inc. (http://www.zend.com)
 * @license   http://framework.zend.com/license/new-bsd New BSD License
 */

/*
 * Set error reporting to the level to which Zend Framework code must comply.
 */
error_reporting(E_ALL | E_STRICT);

if (class_exists('PHPUnit_Runner_Version', true)) {
    $phpUnitVersion = PHPUnit_Runner_Version::id();
    if ('@package_version@' !== $phpUnitVersion && version_compare($phpUnitVersion, '4.0.0', '<')) {
        echo 'This version of PHPUnit (' . PHPUnit_Runner_Version::id() . ') is not supported'
           . ' in the zend-{COMPONENT} unit tests. Supported is version 4.0.0 or higher.'
           . ' See also the CONTRIBUTING.md file in the component root.' . PHP_EOL;
        exit(1);
    }
    unset($phpUnitVersion);
}

/*
 * Determine the root, library, and tests directories of the framework
 * distribution.
 */
$root    = realpath(dirname(__DIR__));
$library = "$root/src";
$tests   = "$root/test";

/**
 * Setup autoloading
 */
require __DIR__ . '/../vendor/autoload.php';

/*
 * Load the user-defined test configuration file, if it exists; otherwise, load
 * the default configuration.
 */
require_once (
    is_readable($tests . DIRECTORY_SEPARATOR . 'TestConfiguration.php')
    ? $tests . DIRECTORY_SEPARATOR . 'TestConfiguration.php'
    : $tests . DIRECTORY_SEPARATOR . 'TestConfiguration.php.dist'
);

if (defined('TESTS_GENERATE_REPORT') && TESTS_GENERATE_REPORT === true) {
    $codeCoverageFilter = new PHP_CodeCoverage_Filter();

    $lastArg = end($_SERVER['argv']);
    if (is_dir($tests . '/' . $lastArg)) {
        $codeCoverageFilter->addDirectoryToWhitelist($library . '/' . $lastArg);
    } elseif (is_file($tests . '/' . $lastArg)) {
        $codeCoverageFilter->addDirectoryToWhitelist(dirname($library . '/' . $lastArg));
    } else {
        $codeCoverageFilter->addDirectoryToWhitelist($library);
    }

    /*
     * Omit from code coverage reports the contents of the tests directory
     */
    $codeCoverageFilter->addDirectoryToBlacklist($tests, '');
    $codeCoverageFilter->addDirectoryToBlacklist(PEAR_INSTALL_DIR, '');
    $codeCoverageFilter->addDirectoryToBlacklist(PHP_LIBDIR, '');

    unset($codeCoverageFilter);
}


/**
 * Start output buffering, if enabled
 */
if (defined('TESTS_ZEND_OB_ENABLED') && constant('TESTS_ZEND_OB_ENABLED')) {
    ob_start();
}

/*
 * Unset global variables that are no longer needed.
 */
unset($root, $library, $tests);
