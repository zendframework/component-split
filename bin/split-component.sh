#!/bin/bash
echo "ZF2 Component Split Tool, v0.1.0"
echo

# Variables to set via options
ZF2_PATH=zf2-migrate
PHP_EXEC=$(which php)
COMPONENT=
PHPUNIT_DIST=
TEST_CONFIG_DIST=
TEST_CONFIG_TRAVIS=
PHPCS_CONFIG=
TRAVIS_CONFIG=
README=

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
    echo "-u <phpunit.xml.dist>  Path to phpunit.xml.dist to use for this component; a template is used by default"
    echo "-t <TestConfiguration.php.dist>  Path to the component's TestConfiguration.php.dist file"
    echo "-i <TestConfiguration.php.travis>  Path to the component's TestConfiguration.php.travis file"
    echo "-s <.php_cs>           Path to the component-specific .php_cs file, if any"
    echo "-T <.travis.yml>       Path to the component-specific .travis.yml file, if any"
    echo "-r <README.md>         Path to the component-specific README.md file; a template is used by default"

    exit $STATUS
}

# Parse incoming options
while getopts ":hc:z:p:u:t:i:s:T:r:" opt ;do
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
        t)
            TEST_CONFIG_DIST=$OPTARG
            ;;
        i)
            TEST_CONFIG_TRAVIS=$OPTARG
            ;;
        s)
            PHPCS_CONFIG=$OPTARG
            ;;
        T)
            TRAVIS_CONFIG=$OPTARG
            ;;
        r)
            README=$OPTARG
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

# Marshal and validate incoming arguments
ERROR=0
if [[ $COMPONENT = "" ]]; then
    echo "-c <COMPONENT> is REQUIRED" >&2
    ERROR=1
    help 1
fi

if [[ "$PHPUNIT_DIST" != "" ]]; then
    PHPUNIT_DIST=$(readlink -f "$PHPUNIT_DIST" 2>&1)
    if [[ "$PHPUNIT_DIST" = "" ]]; then
        echo "-u <phpunit.xml.dist> MUST be a valid filename" >&2
        ERROR=1
    fi
fi

TEST_CONFIG_DIST=$(readlink -f "$TEST_CONFIG_DIST" 2>&1)
if [[ "$TEST_CONFIG_DIST" = "" ]]; then
    echo "-t <TestConfiguration.php.dist> is REQUIRED, and must be a valid filename" >&2
    ERROR=1
fi

TEST_CONFIG_TRAVIS=$(readlink -f "$TEST_CONFIG_TRAVIS" 2>&1)
if [[ "$TEST_CONFIG_TRAVIS" = "" ]]; then
    echo "-t <TestConfiguration.php.travis> is REQUIRED, and must be a valid filename" >&2
    ERROR=1
fi

if [[ "$PHPCS_CONFIG" != "" ]]; then
    PHPCS_CONFIG=$(readlink -f "$PHPCS_CONFIG" 2>&1)
    if [[ "$PHPCS_CONFIG" = "" ]]; then
        echo "-s <.php_cs> MUST be a valid filename" >&2
        ERROR=1
    fi
fi

if [[ "$TRAVIS_CONFIG" != "" ]]; then
    TRAVIS_CONFIG=$(readlink -f "$TRAVIS_CONFIG" 2>&1)
    if [[ "$TRAVIS_CONFIG" = "" ]]; then
        echo "-T <.travis.yml> MUST be a valid filename" >&2
        ERROR=1
    fi
fi

if [[ "${README}" != "" ]]; then
    README=$(readlink -f "${README}" 2>&1)
    if [[ "${README}" = "" ]]; then
        echo "-r <README.md> MUST be a valid filename" >&2
        ERROR=1
    fi
fi

# Report errors and exit
if [[ $ERROR != 0 ]]; then
    help $ERROR
fi

# Begin!
echo "Splitting component ${COMPONENT}"
echo "Using:"
echo "    PHP:                           ${PHP_EXEC}"
echo "    ZF2 path:                      ${ZF2_PATH}"
echo "    TestConfiguration.php.dist:    ${TEST_CONFIG_DIST}"
echo "    TestConfiguration.php.travis:  ${TEST_CONFIG_TRAVIS}"
if [[ "" != "${PHPUNIT_DIST}" ]]; then echo "    phpunit.xml.dist:              ${PHPUNIT_DIST}" ; fi
if [[ "" != "${PHPCS_CONFIG}" ]]; then echo "    .php_cs:                       ${PHPCS_CONFIG}" ; fi
if [[ "" != "${TRAVIS_CONFIG}" ]]; then echo "    .travis.yml:                   ${TRAVIS_CONFIG}" ; fi
if [[ "" != "${README}" ]]; then echo "    README.md:                     ${README}" ; fi
echo

# Script-specific variables
ZF2_REPO="git://github.com/zendframework/zf2"
ROOT_DIR=$(readlink -f $(dirname $0)/..)
TMP_DIR=${ROOT_DIR}/tmp

# Clone the ZF2 repo
if [[ -d "$ZF2_PATH" ]]; then
    (
        cd "$ZF2_PATH" ; 
        git reset --hard origin/master ;
    )
else
    git clone $ZF2_REPO $ZF2_PATH ;
fi
ZF2_PATH=$(readlink -f ${ZF2_PATH})

# Ensure we have an actual component
if [[ ! -d "${ZF2_PATH}/library/Zend/${COMPONENT}" ]];then
    echo "Invalid component name '${COMPONENT}'!" >&2
    exit 1
fi

# Create a temporary directory for the composer.json
if [[ ! -d "${TMP_DIR}" ]];then
    mkdir "${TMP_DIR}"
fi

# Copy the composer.json for the component to the temporary directory
cp "${ZF2_PATH}/library/Zend/${COMPONENT}/composer.json" "${TMP_DIR}/composer.json"

# Perform the tree-filter
echo "Executing tree-filter"
(
    cd $ZF2_PATH ;
    git filter-branch -f --prune-empty \
        --tree-filter "
            ${PHP_EXEC} ${ROOT_DIR}/bin/tree-filter.php \
                ${COMPONENT} \
                ${ROOT_DIR} \
                ${PHP_EXEC} \
                ${README:='(none)'} \
                ${TRAVIS_CONFIG:='(none)'} \
                ${PHPCS_CONFIG:='(none)'} \
                ${TEST_CONFIG_DIST} \
                ${TEST_CONFIG_TRAVIS} \
                ${PHPUNIT_DIST:='(none)'}
"       --msg-filter "
            sed -re 's/(^|[^a-zA-Z])(\#[1-9][0-9]*)/\1zendframework\/zf2\2/g'
" --tag-name-filter cat release-2.0.0rc3..HEAD ;
    for TAG in dev1 dev2 dev3 dev4 beta1 beta2 beta3 beta4 beta5 rc1 rc2 rc3 rc4 rc5 rc6 rc7; do
        git tag -d release-2.0.o${TAG} ;
    done ;
    git gc --aggressive ;
)

echo
echo "Done!"
echo "Split component is in ${ZF2_PATH}; review for history and tags."
