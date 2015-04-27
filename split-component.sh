#!/bin/bash
echo "ZF2 Component Split Tool, v0.1.0"
echo

# Variables to set via options
ZF2_PATH=zf2-migrate
PHP_EXEC=$(which php)
COMPONENT=
PHPUNIT_DIST=

# Functions
function help {
    STATUS=0
    if [[ $# -gt 0 ]]; then
        STATUS=$1
    fi

    echo "Usage:"
    echo "-h                     Help; this message"
    echo "-c <Component>         Component to split out"
    echo "-z <ZF2 path>          Path in which to clone ZF2; defaults to 'zf2-migrate'"
    echo "-p <PHP executable>    PHP executable to use (for composer rewrite); defaults to /usr/bin/env php"
    echo "-u <phpunit.xml.dist>  Path to phpunit.xml.dist to use for this component"

    exit $STATUS
}

# Parse incoming options
while getopts ":hc:z:p:u:" opt ;do
    case $opt in
        h)
            help
            ;;
        c)
            COMPONENT=$OPTARG
            ;;
        z)
            ZF2_PATH=$OPTARG
            ;;
        p)
            PHP_EXEC=$OPTARG
            ;;
        u)
            PHPUNIT_DIST=$OPTARG
            ;;
        \?)
            echo "Invalid option!"
            help 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument!"
            help 1
            ;;
    esac
done

if [[ $COMPONENT = "" ]]; then
    echo "-c <COMPONENT> is REQUIRED" >&2
    help 1
fi

PHPUNIT_DIST=$(readlink -f $PHPUNIT_DIST 2>&1)

if [[ $PHPUNIT_DIST = "" ]]; then
    echo "-u <phpunit.xml.dist> is REQUIRED, and must be a valid filename" >&2
    help 1
fi

echo "Using ZF2 path ${ZF2_PATH}"
echo "Splitting component ${COMPONENT}"
echo "Using phpunit configuration in ${PHPUNIT_DIST}"

# Script-specific variables
ZF2_REPO="git://github.com/zendframework/zf2"
COMPOSER_REWRITER=$(readlink -f composer-rewriter.php)

# Clone the ZF2 repo
if [[ -d "$ZF2_PATH" ]]; then
    (
        cd "$ZF2_PATH" ; 
        git reset --hard origin/master ;
    )
else
    git clone $ZF2_REPO $ZF2_PATH ;
fi

# Ensure we have an actual component
if [[ ! -d "${ZF2_PATH}/library/Zend/${COMPONENT}" ]];then
    echo "Invalid component name '${COMPONENT}'!" >&2
    exit 1
fi

# Perform the tree-filter
echo "Executing tree-filter"
(
    cd $ZF2_PATH ;
    git filter-branch -f --prune-empty --tree-filter "
        mkdir -p .zend-${COMPONENT,,}-migrate/{src-tree,test} ;
        if [ ! -d "library/Zend/${COMPONENT}" ]
        then
            rm -rf bin demos library resources test tests vendor working *.md *.json *.lock 2>/dev/null ;
        else
            rsync -a library/Zend/${COMPONENT} .zend-${COMPONENT,,}-migrate/src-tree/ ;
            if [ -d "tests/Zend" ]
            then
                rsync -a tests/Zend/${COMPONENT} .zend-${COMPONENT,,}-migrate/test/ ;
            else
                rsync -a tests/ZendTest/${COMPONENT} .zend-${COMPONENT,,}-migrate/test/ ;
            fi ;
            cp -a tests/*.* .zend-${COMPONENT,,}-migrate/test/ ;
            cp -a tests/.gitignore .zend-${COMPONENT,,}-migrate/test/ ;
            rm -f .zend-${COMPONENT,,}-migrate/test/run-tests.* ;
            rm -rf bin demos library resources test tests vendor working *.md *.json *.lock  2>/dev/null ;
        fi ;
        mv .zend-${COMPONENT,,}-migrate/* . ;
        mv src-tree/${COMPONENT} src ;
        mv src/*.json src/*.md . 2>/dev/null ;
        cp ${PHPUNIT_DIST} . ;
        $PHP_EXEC $COMPOSER_REWRITER "${COMPONENT}" ;
        rmdir .zend-${COMPONENT,,}-migrate ;
" release-2.3.6..HEAD ;
    git gc --aggressive
)

echo
echo "Done!"
echo "Split component is in ${ZF2_PATH}; review for history and tags."
