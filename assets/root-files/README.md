root-files
==========

In this directory are a number of files used to populate the root directory of
the component. They include:

- `LICENSE.txt`, the license for the component (BSD-3-Clause)
- `coveralls.yml`, the configuration for coveralls.io.
- `gitattributes`, the `.gitattributes` to use for the component.
- `gitignore`, the `.gitignore` to use for the component.
- `php_cs`, the `.php_cs` rules to use for the component.
- `travis.yml`, the `.travis.yml` to use for the component.

In most cases, you can use each of these as-is. In some cases, you will need to
provide alternate `php_cs` and/or `travis.yml` files. To do so, copy them
elsewhere, modify them, and provide them to `split-component.sh` using the `-s`
and `-T` options, respctively.
