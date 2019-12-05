Zend Framework Component Split Utilities
========================================

> ## Repository abandoned 2019-12-05
>
> This repository is no longer maintained.

This repository contains utilities for splitting Zend Framework 2 components out
of the main ZF2 repository and into their own repositories, complete with
history.

## Splitting a component

The primary entry-point utility is `bin/split.sh`. This script accepts up to two
arguments:

- `-c COMPONENT` for the component name (it should be the same as it appears in
  the ZF2 library directory)
- `-p PHP` for the path to the PHP executable (if it cannot be found via `which
  php`)

This script will use the various files located under
`assets/root-files/COMPONENT` to split the component.

As an example:

```console
$ ./bin/split.sh -c Authentication
```

Two components have special rules: `Zend\Permissions\Acl` and
`Zend\Permissinos\Rbac`; these are invoked as simply `Acl` and `Rbac`,
respectively.

The files will be split into a directory named after the component; e.g.,
Authentication becomes `zend-authentication`, Acl becomes
`zend-permissions-acl`, etc. This allows parallel runs in the same directory.

### Custom split

The heavy-lifting utility is `bin/split-component.sh`. This script accepts the component
name, paths to a number of component-specific assets, and then performs a `git
filter-branch` that rewrites each commit to only contain the source code and
tests for the given component, as well as repository assets such as the license,
README, and QA tool configuration.

It's usage is as follows:

```console
ZF2 Component Split Tool, v0.1.0

Usage:
-h                      Help; this message
-c <Component>          Component to split out (REQUIRED)
-u <phpunit.xml.dist>   Path to phpunit.xml.dist to use for this component (REQUIRED)
-t <phpunit.xml.travis> Path to the component's TestConfiguration.php.dist file (REQUIRED)
-z <ZF2 path>           Path in which to clone ZF2; defaults to 'zf2-migrate'
-s <.php_cs>            Path to the component-specific .php_cs file, if any
-T <.travis.yml>        Path to the component-specific .travis.yml file, if any
-r <README.md>          Path to the component-specific README.md file; a template is used by default
-p <PHP executable>     PHP executable to use (for composer rewrite); defaults to /usr/bin/env php
```

The required options are:

- `-c <Component>` to provide the component name. This should be the name of the
  directory in which it appears under the `library/Zend/` tree.
- `-u <phpunit.xml.dist>` to provide the customized,
  component-specific `phpunit.xml.dist` file. A full example is
  under `assets/root-files/`; copy that to another location and edit it.
- `-t <phpunit.xml.travis>` to provide the customized,
  component-specific `phpunit.xml.travis` file. A full example is
  under `assets/root-files/`; copy that to another location and edit it.

We recommend that you create an appropriate, minimal `README.md` file to use as
well, in order to provide details around the purpose of a component. Do not
provide specifics on usage, as usage may have changed over the lifetime of the
component.

Finally, you may need to customize the `.php_cs` and/or `.travis.yml` files if
the component you're splitting has additional files to ignore for coding
standards, or dependencies on non-standard extensions when testing. Write these
to files locally, and specify their paths to the tool.

As an example:

```console
# Assume the phpunit.xml.* files were already prepared and are in the root
# directory when running.
$ ./bin/split-component.sh \
> -c Dom \
> -u phpunit.xml.dist \
> -t phpunit.xml.travis 2>&1 | tee -a split.log
```

> ### Note on duration
>
> Splitting a component takes a very, very long time due to the amount of
> history in Zend Framework — over 20k commits! The process does not consume a
> large number of system resources, but will take between 4 and 6 hours
> depending on your hardware (and possibly longer).
>
> As such, we recommend:
>
> - Do not reboot mid-process!
> - Run in screen or tmux.
> - Pipe STDERR and STDOUT to a log file; if you use the `tee` command, you can
>   even tail a log file from another terminal window. See the example above for
>   how to accomplish that.

Once done, enter the directory in which the split occurred, and check the
`composer.json` across a number of tags to verify it looks okay; run `composer
install` and `phpunit` as spot-checks. (This will only work within tags!)

> ### Note on unit tests
>
> We've made the decision to support a single version of PHPUnit across the
> entire history of each component. In some cases, this will fail, due to
> differences in PHPUnit syntax, missing dependencies, etc. The main thing is
> to ensure it runs at all.

Once done, create a component repository under your own username on GitHub, add
it as a remote to your local repository, and push the full history to it:

```console
$ cd zf2-migrate
$ git remote add username git@github.com:username/zend-{component}.git
$ git push --all --tags username
```

(Where "username" is your GitHub username, and {component} is the component
name.)

Once done, drop an email to zf-devteam@zend.com indicating the component you've
split and the URI to your GitHub repository so we can verify. Once we have,
we'll add you to the team for the canonical repository, and have you push to it.