#!/bin/bash
echo "ZF2 Component Split"
echo

ROOT_DIR=$(readlink -f $(dirname $0)/..)

# Variables to set via options
COMPONENT=
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
    echo "-p <PHP executable>     PHP executable to use (for composer rewrite); defaults to /usr/bin/env php"

    exit $STATUS
}

# Parse incoming options
while getopts ":hc:p:" opt ;do
    case $opt in
        h)
            help
            ;;
        c)
            COMPONENT=$OPTARG
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
if [[ $COMPONENT = "" ]]; then
    echo "-c <COMPONENT> is REQUIRED" >&2
    help 1
fi

# Begin!
echo "Splitting component ${COMPONENT}"
echo "Using:"
echo "    PHP:                           ${PHP_EXEC}"
echo

COMPONENT_PATH=${COMPONENT};

if [[ "${COMPONENT}" = "Acl" ]];then
    COMPONENT="Permissions/Acl";
    COMPONENT_PATH="Permissions-Acl"
fi
if [[ "${COMPONENT}" = "Rbac" ]];then
    COMPONENT="Permissions/Rbac";
    COMPONENT_PATH="Permissions-Rbac"
fi

PHPUNIT_DIST=${ROOT_DIR}/assets/root-files/${COMPONENT_PATH}/phpunit.xml.dist
PHPUNIT_TRAVIS=${ROOT_DIR}/assets/root-files/${COMPONENT_PATH}/phpunit.xml.travis
PHPCS=${ROOT_DIR}/assets/root-files/${COMPONENT_PATH}/php_cs
README=${ROOT_DIR}/assets/root-files/${COMPONENT_PATH}/README.md

${ROOT_DIR}/bin/split-component.sh -c "${COMPONENT}" -p "${PHP_EXEC}" -u "${PHPUNIT_DIST}" -t "${PHPUNIT_TRAVIS}" -r "${README}" -s "${PHPCS}"
