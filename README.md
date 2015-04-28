Zend Framework Component Split Utilities
========================================

This repository contains utilities for splitting Zend Framework 2 components out
of the main ZF2 repository and into their own repositories, complete with
history.

## Splitting a component

The main utility is `bin/split-component.sh`. This script accepts the component
name, paths to a number of component-specific assets, and then performs a `git
filter-branch` that rewrites each commit to only contain the source code and
tests for the given component, as well as repository assets such as the license,
README, and QA tool configuration.

It's usage is as follows:

```console
ZF2 Component Split Tool, v0.1.0

Usage:
-h                     Help; this message
-c <Component>         Component to split out
-z <ZF2 path>          Path in which to clone ZF2; defaults to 'zf2-migrate'
-p <PHP executable>    PHP executable to use (for composer rewrite); defaults to /usr/bin/env php
-u <phpunit.xml.dist>  Path to phpunit.xml.dist to use for this component; a template is used by default
-t <TestConfiguration.php.dist>  Path to the component's TestConfiguration.php.dist file
-i <TestConfiguration.php.travis>  Path to the component's TestConfiguration.php.travis file
-s <.php_cs>           Path to the component-specific .php_cs file, if any
-T <.travis.yml>       Path to the component-specific .travis.yml file, if any
-r <README.md>         Path to the component-specific README.md file; a template is used by default
```

The required options are:

- `-c <Component>` to provide the component name. This should be the name of the
  directory in which it appears under the `library/Zend/` tree.
- `-t <TestConfiguration.php.dist>` to provide the customized,
  component-specific `TestConfiguration.php.dist` file. A full example is
  under `assets/test-files/`; copy that to another location and edit it.
- `-i <TestConfiguration.php.travis>` to provide the customized,
  component-specific `TestConfiguration.php.travis` file. A full example is
  under `assets/test-files/`; copy that to another location and edit it.

We recommend that you create an appropriate, minimal `README.md` file to use as
well, in order to provide details around the purpose of a component. Do not
provide specifics on usage, as usage may have changed over the lifetime of the
component.

Finally, you may need to customize the `.php_cs`, `.travis.yml`, and/or
`phpunit.xml.dist` file if the component you're splitting has additional files
to ignore for coding standards, dependencies on non-standard extensions when
testing, or defines additional unit test suites/groups. Write these to files
locally, and specify their paths to the tool.

As an example:

```console
# Assume the TestConfiguration.* files were already prepared and are in the root
# directory when running.
$ ./bin/split-component.sh \
> -c Dom \
> -t TestConfiguration.php.dist \
> -i TestConfiguration.php.travis 2>&1 | tee -a split.log
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
install` and `phpunit` as spot-checks.

> ### Note on unit tests
>
> We've made the decision to support a single version of PHPUnit across the
> entire history of each component. In some cases, this will fail, due to
> differences in PHPUnit syntax, missing dependencies, etc. The main thing is
> to ensure it runs at all.

Now that you've done that, in order to cleanup and remove unused objects, clone
the repository; assuming you used the default of `zf2-migrate` for the ZF2 path
in which to perform the split, do the following:

```console
$ git clone zf2-migrate zend-{component}
```

Once done, create a component repository under your own username on GitHub, add
it as a remote to your local repository, and push the full history to it:

```console
$ cd zend-{component}
$ git remote add username git@github.com:username/zend-{component}.git
$ git push --all --tags username
```

(Where "username" is your GitHub username, and {component} is the component
name.)

Once done, drop an email to zf-devteam@zend.com indicating the component you've
split and the URI to your GitHub repository so we can verify. Once we have,
we'll add you to the team for the canonical repository, and have you push to it.
