#!/bin/bash
PACKAGE="gnome-shell-extension-shellshape"
DEBEMAIL="github@mgor.se"
DEBFULLNAME="docker-ubuntu-${PACKAGE}-builder"
DEBCOPYRIGHT="debian/copyright"
USER=builder
URL="https://github.com/timbertson/shellshape"
DISTRO="$(lsb_release -sc)"

export DISTRO URL USER DEBCOPYRIGHT DEBFULLNAME DEBEMAIL PACKAGE

cleanup() {
    local rv=$?
    chown -R "${USER}:${USER}" /usr/local/src || true

    if (( rv == 0 )); then
        rm -rf /usr/local/src/shellshape/
        rm -rf "/usr/local/src/${PACKAGE}_${VERSION}/"
    fi

    exit $rv
}

run() {
    sudo -Eu "${USER}" -H "${@}"
}

trap cleanup EXIT

# prepare dev enviroment
groupadd --gid "${GROUP_ID}" "${USER}" && \
useradd -M -N -u "${USER_ID}" -g "${GROUP_ID}" "${USER}" && \
mkdir "/home/${USER}" && \
chown "${USER}:${USER}" "/home/${USER}" && \
chown "${USER}" .

# get source
run git clone "${URL}.git" "shellshape" || { echo "failed to setup build env."; exit 1; }

# build extension
pushd shellshape
VERSION="$(cat VERSION)-$(date +"%Y%m%d")-$(git rev-parse --short HEAD)"
export VERSION
run tools/gup compile || { echo "failed to build"; exit 1; }
popd

# prepare for packaging
mkdir -p "${PACKAGE}_${VERSION}/DEBIAN"
pushd "${PACKAGE}_${VERSION}"
mkdir -p usr/share/{gnome-shell/extensions,doc/gnome-shell-extension-shellshape}
rsync -aL \
    --exclude ".git*" \
    --exclude "*gup" \
    --exclude "*.po*" \
    --exclude "Makefile" \
    ../shellshape/shellshape/ usr/share/gnome-shell/extensions/shellshape@gfxmonk.net

# include documentation
cp ../shellshape/LICENCE usr/share/doc/gnome-shell-extension-shellshape/copyright
cp ../shellshape/README.md usr/share/doc/gnome-shell-extension-shellshape/

# patch supported versions
python3 <<EOP
import sys
import json
with open('usr/share/gnome-shell/extensions/shellshape@gfxmonk.net/metadata.json', 'r+') as fd:
    metadata = json.load(fd)
    metadata['shell-version'].extend(['3.23', '3.24'])
    fd.seek(0)
    fd.write(json.dumps(metadata, indent=2))
    fd.truncate()
EOP

chown -R root:root .

# build package
cat > DEBIAN/control <<EOF
Package: ${PACKAGE}
Architecture: all
Maintainer: ${DEBFULLNAME}
Depends: gnome-shell (>= 3.18), gnome-tweak-tool, dconf-editor
Version: ${VERSION}
Description: A tiling window manager extension for gnome-shell
 Many tiling window managers are an all-or-nothing affair, shellshape
 allows you to tile your windows when it makes sense, and still
 provides powerful direct manipulation when you need it. You don't
 have to give up any of the gnome features you like, so it makes for
 a very smooth learning curve.
EOF

popd


if ! dpkg-deb --build "${PACKAGE}_${VERSION}"; then
    echo "Build failed!"
    exit 1
fi

exit 0
