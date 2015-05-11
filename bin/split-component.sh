#!/bin/bash
echo "ZF2 Component Split Tool, v0.1.0"
echo

# General variables
ZF2_REPO="git://github.com/zendframework/zf2"
ROOT_DIR=$(readlink -f $(dirname $0)/..)
TMP_DIR=${ROOT_DIR}/tmp
ORIGIN_TAG="bb50be26b24a9e0e62a8f4abecce53259d707b61"
REMOVE_TAGS=("release-2.0.0dev1" "release-2.0.0dev2" "release-2.0.0dev3" "release-2.0.0dev4" "release-2.0.0beta1" "release-2.0.0beta2" "release-2.0.0beta3" "release-2.0.0beta4" "release-2.0.0beta5" "release-2.0.0rc1" "release-2.0.0rc2" "release-2.0.0rc3" "release-2.0.0rc4" "release-2.0.0rc5" "release-2.0.0rc6" "release-2.0.0rc7")
PRUNE_BEFORE="bb50be26b24a9e0e62a8f4abecce53259d707b61"

# Variables to set via options
COMPONENT=
PHPUNIT_DIST=
PHPUNIT_TRAVIS=
ZF2_PATH=zf2-migrate
PHPCS_CONFIG=${ROOT_DIR}/assets/root-files/php_cs
TRAVIS_CONFIG=${ROOT_DIR}/assets/root-files/travis.yml
README=
PHP_EXEC=$(which php)

# Functions
function help {
    STATUS=0
    if [[ $# -gt 0 ]]; then
        STATUS=$1
    fi

    echo "Usage:"
    echo "-h                      Help; this message"
    echo "-c <Component>          Component to split out (REQUIRED)"
    echo "-u <phpunit.xml.dist>   Path to phpunit.xml.dist to use for this component (REQUIRED)"
    echo "-t <phpunit.xml.travis> Path to the component's TestConfiguration.php.dist file (REQUIRED)"
    echo "-z <ZF2 path>           Path in which to clone ZF2; defaults to 'zf2-migrate'"
    echo "-s <.php_cs>            Path to the component-specific .php_cs file, if any"
    echo "-T <.travis.yml>        Path to the component-specific .travis.yml file, if any"
    echo "-r <README.md>          Path to the component-specific README.md file; a template is used by default"
    echo "-p <PHP executable>     PHP executable to use (for composer rewrite); defaults to /usr/bin/env php"

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
        u)
            PHPUNIT_DIST=$OPTARG
            ;;
        t)
            PHPUNIT_TRAVIS=$OPTARG
            ;;
        z)
            ZF2_PATH=$OPTARG
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
        p)
            PHP_EXEC=$OPTARG
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
fi

PHPUNIT_DIST=$(readlink -f "${PHPUNIT_DIST}" 2>&1)
if [[ "${PHPUNIT_DIST}" = "" ]]; then
    echo "-u <phpunit.xml.dist> MUST be a valid filename and is REQUIRED" >&2
    ERROR=1
fi

PHPUNIT_TRAVIS=$(readlink -f "${PHPUNIT_TRAVIS}" 2>&1)
if [[ "${PHPUNIT_TRAVIS}" = "" ]]; then
    echo "-t <phpunit.xml.travis> MUST be a valid filename and is REQUIRED" >&2
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

if [ "${COMPONENT}" = "Permissions/Rbac" ] || [ "${COMPONENT}" = "Test" ];then
    ORIGIN_TAG="c74383840bea3646b83f9ff5d910eae9a114227e"
    REMOVE_TAGS+=("release-2.0.8")
    PRUNE_BEFORE="345a8cbedbe8de8a25bf18579fe54d169ac5075a"
fi

# Begin!
echo "Splitting component ${COMPONENT}"
echo "Using:"
echo "    PHP:                           ${PHP_EXEC}"
echo "    ZF2 path:                      ${ZF2_PATH}"
echo "    phpunit.xml.dist:              ${PHPUNIT_DIST}"
echo "    phpunit.xml.travis:            ${PHPUNIT_TRAVIS}"
if [[ "" != "${PHPCS_CONFIG}" ]]; then echo "    .php_cs:                       ${PHPCS_CONFIG}" ; fi
if [[ "" != "${TRAVIS_CONFIG}" ]]; then echo "    .travis.yml:                   ${TRAVIS_CONFIG}" ; fi
if [[ "" != "${README}" ]]; then echo "    README.md:                     ${README}" ; fi
echo

# Clone the ZF2 repo
if [[ -d "${ZF2_PATH}" ]]; then
    rm -Rf ${ZF2_PATH} ;
fi
git clone $ZF2_REPO $ZF2_PATH ;
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
zsh:1: command not found: k
(
    cd ${ZF2_PATH} ;
    git remote rm origin ;
    echo "Removing unneeded tags" ;
    git tag -d last-docs-commit ;
    for TAG in "${REMOVE_TAGS[@]}"; do
        git tag -d ${TAG} ;
    done ;
    echo "Executing tree-filter" ;
    git filter-branch -f \
        --tree-filter "
            ${PHP_EXEC} ${ROOT_DIR}/bin/tree-filter.php \
                ${COMPONENT} \
                ${ROOT_DIR} \
                ${PHP_EXEC} \
                ${PHPUNIT_DIST} \
                ${PHPUNIT_TRAVIS} \
                ${README:='(none)'} \
                ${TRAVIS_CONFIG:='(none)'} \
                ${PHPCS_CONFIG:='(none)'}
"       --msg-filter "
            sed -re 's/(^|[^a-zA-Z])(\#[1-9][0-9]*)/\1zendframework\/zf2\2/g'
"       --commit-filter 'git_commit_non_empty_tree "$@"' \
        --tag-name-filter cat \
        ${ORIGIN_TAG}..HEAD ;
    echo "Removing empty merge commits" ;
    git filter-branch -f \
        --commit-filter '
            if [ z$1 = z`git rev-parse $3^{tree}` ];then
                skip_commit "$@";
            else
                git commit-tree "$@";
            fi
'       --tag-name-filter cat ${PRUNE_BEFORE}..HEAD ;
    git reflog expire --expire=now --all ;
    git gc --prune=now --aggressive ;
)

echo
echo "Done!"
echo "Split component is in ${ZF2_PATH}; review for history and tags."
