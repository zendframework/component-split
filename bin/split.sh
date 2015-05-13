#!/bin/bash
echo "ZF2 Component Split"
echo

ROOT_DIR=$(readlink -f $(dirname $0)/..)

# Variables to set via options
COMPONENT=
PHP_EXEC=$(which php)
ZF2_PATH=

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
    echo "-r <path>               Path in which to create split component; defaults to zend-{component}"

    exit $STATUS
}

# Parse incoming options
while getopts ":hc:p:r:" opt ;do
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
        r)
            ZF2_PATH=$OPTARG
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
    if [[ "${ZF2_PATH}" = "" ]];then
        ZF2_PATH="zend-permissions-acl"
    fi
else
    if [[ "${COMPONENT}" = "Rbac" ]];then
        COMPONENT="Permissions/Rbac";
        COMPONENT_PATH="Permissions-Rbac"
        if [[ "${ZF2_PATH}" = "" ]];then
            ZF2_PATH="zend-permissions-rbac"
        fi
    else
        COMPONENT_PATH=${COMPONENT}
        if [[ "${ZF2_PATH}" = "" ]];then
            ZF2_PATH="zend-$(echo ${COMPONENT} | $PHP_EXEC ${ROOT_DIR}/bin/normalize.php)"
        fi
    fi
fi

ASSETS="${ROOT_DIR}/assets/root-files/${COMPONENT_PATH}"

PHPUNIT_DIST=${ASSETS}/phpunit.xml.dist
PHPUNIT_TRAVIS=${ASSETS}/phpunit.xml.travis
PHPCS=${ASSETS}/php_cs
README=${ASSETS}/README.md

echo "Splitting ${COMPONENT} using:"
echo "    REPO PATH:             ${ZF2_PATH}"
echo "    README:                ${README}"
echo "    phpunit.xml.dist:      ${PHPUNIT_DIST}"
echo "    phpunit.xml.travis:    ${PHPUNIT_TRAVIS}"
echo "    php_cs:                ${PHPCS}"
echo

${ROOT_DIR}/bin/split-component.sh -c "${COMPONENT}" -z "${ZF2_PATH}" -p "${PHP_EXEC}" -u "${PHPUNIT_DIST}" -t "${PHPUNIT_TRAVIS}" -r "${README}" -s "${PHPCS}"
