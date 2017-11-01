#!/bin/bash -ex

function mtime() {
    stat -c %Y $1
}

# Go to top of blueprint tree
cd $(dirname ${BASH_SOURCE[0]})/..
TOP=${PWD}

export TEMPDIR=$(mktemp -d -t blueprint.test.XXX)

function cleanup() {
    cd "${TOP}"
    rm -rf "${TEMPDIR}"
}
trap cleanup EXIT

export OUTDIR="${TEMPDIR}/out"
mkdir "${OUTDIR}"

export SRCDIR="${TEMPDIR}/src"
cp -r tests/test_tree "${SRCDIR}"
ln -s "${TOP}" "${SRCDIR}/blueprint"

cd "${OUTDIR}"
export BLUEPRINTDIR=${SRCDIR}/blueprint
${SRCDIR}/blueprint/bootstrap.bash $@
./blueprint.bash

OLDTIME_BOOTSTRAP=$(mtime .bootstrap/build.ninja)
OLDTIME=$(mtime build.ninja)

sleep 2
./blueprint.bash

if [ ${OLDTIME} != $(mtime build.ninja) ]; then
    echo "unnecessary build.ninja regeneration for null build" >&2
    exit 1
fi

if [ ${OLDTIME_BOOTSTRAP} != $(mtime .bootstrap/build.ninja) ]; then
    echo "unnecessary .bootstrap/build.ninja regeneration for null build" >&2
    exit 1
fi

mkdir ${SRCDIR}/newglob

sleep 2
./blueprint.bash

if [ ${OLDTIME} != $(mtime build.ninja) ]; then
    echo "unnecessary build.ninja regeneration for glob addition" >&2
    exit 1
fi
if [ ${OLDTIME_BOOTSTRAP} != $(mtime .bootstrap/build.ninja) ]; then
    echo "unnecessary .bootstrap/build.ninja regeneration for glob addition" >&2
    exit 1
fi

touch ${SRCDIR}/newglob/Blueprints

sleep 2
./blueprint.bash

if [ ${OLDTIME} = $(mtime build.ninja) ]; then
    echo "Failed to rebuild build.ninja for glob addition" >&2
    exit 1
fi
if [ ${OLDTIME_BOOTSTRAP} = $(mtime .bootstrap/build.ninja) ]; then
    echo "Failed to rebuild .bootstrap/build.ninja for glob addition" >&2
    exit 1
fi

OLDTIME=$(mtime build.ninja)
OLDTIME_BOOTSTRAP=$(mtime .bootstrap/build.ninja)
rm ${SRCDIR}/newglob/Blueprints

sleep 2
./blueprint.bash

if [ ${OLDTIME} = $(mtime build.ninja) ]; then
    echo "Failed to rebuild build.ninja for glob removal" >&2
    exit 1
fi
if [ ${OLDTIME_BOOTSTRAP} = $(mtime .bootstrap/build.ninja) ]; then
    echo "Failed to rebuild .bootstrap/build.ninja for glob removal" >&2
    exit 1
fi

OLDTIME=$(mtime build.ninja)
OLDTIME_BOOTSTRAP=$(mtime .bootstrap/build.ninja)
rmdir ${SRCDIR}/newglob

sleep 2
./blueprint.bash

if [ ${OLDTIME} != $(mtime build.ninja) ]; then
    echo "unnecessary build.ninja regeneration for glob removal" >&2
    exit 1
fi
if [ ${OLDTIME_BOOTSTRAP} != $(mtime .bootstrap/build.ninja) ]; then
    echo "unnecessary .bootstrap/build.ninja regeneration for glob removal" >&2
    exit 1
fi
