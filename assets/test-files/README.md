test-files
==========

This directory contains assets for the `test/` directory of a component. They
include:

- `gitignore`, the files under the `test/` tree to ignore
- `Bootstrap.php`, the test bootstrap. This file is templated, and will be
  updated with the component name in the file docblock and in error messages.
- `phpunit.xml.dist`, the basic PHPUnit configuration; if this version does not
  work for the given component, create a new one, and specify your version in
  using the `-c` option to `split-component.sh`.

The directory also contains two files that you will need to copy, edit, and
provide to `split-component.sh`:

- `TestConfiguration.php.dist`, which should contain the component-specific test
  configuration options. Some options are marked global, and should always be
  used; anything else unrelated to your component should be removed. Provide the
  updated file to `split-component.sh` via the `-t` option.
- `TestConfiguration.php.travis`, which contains the configuration options to be
  used when run under the Travis-CI environment. Again, remove any that are
  not marked global, and/or which are irrelevant to the component. Provide the
  updated file to `split-component.sh` via the `-i` option.
