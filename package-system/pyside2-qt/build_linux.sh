#!/bin/bash


function usage()
{
	cat << HEREDOC
Usage: $PROG_NAME [--git-clone] [--patch]

optional arguments:
    -g, --git-clone       Perform a git-clone
    -p, --patch           Perform a patch

HEREDOC
}

PROG_NAME=$(basename $0)

GIT_CLONE=0
PATCH=0

while (( "$#" )); do
	case "$1" in
		-g|--git-clone)
            GIT_CLONE=1
            shift
            ;;
        -p|--patch)
            PATCH=1
            shift
            ;;
        -h|--help)
            usage
            exit 1
            ;;
        -*|--*=)
            echo "Unsupported flag $1" >&2
            exit 1
            ;;
        *)
            shift
            ;;
     esac
done


GIT_CLONE_URL=https://code.qt.io/cgit/pyside/pyside-setup.git
GIT_TAG=v5.14.2.3
PATCH_FILE=pyside_amzn-v5.14.2.3.patch

mkdir temp

if [ $GIT_CLONE -eq 1 ]
then
	echo Cloning from $GIT_CLONE_URL/$GIT_TAG
	git clone --single-branch --recursive --branch $GIT_TAG $GIT_CLONE_URL temp/pyside-setup
fi


if [ $PATCH -eq 1 ]
then
	pushd temp/pyside-setup
	echo Patching
	git apply ../../$PATCH_FILE
fi

echo /home/ANT.AMAZON.COM/spham/github/o3de/python/runtime/python-3.7.10-rev2-linux/python/bin/python3 -v setup.py build --qmake=/home/ANT.AMAZON.COM/spham/.o3de/3rdParty/packages/qt-5.15.2-rev6-linux/qt/bin/qmake --build-type=all --limited-api=yes > p3_local.log 2>&1
