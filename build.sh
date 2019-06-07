#! /bin/sh -x

uid=5000
image_name=rpkg-f30
build_container=rpkg-build-container

if buildah containers --format '{{.ContainerName}}' \
    | grep "^$build_container$"; then
    bcont=$build_container
else
    bcont=$(buildah from --name rpkg-build-container "${1:-fedora:30}")
fi
buildah config --user 0 "$bcont"

if ! buildah run "$bcont" rpm -q rpkg; then
    buildah run "$bcont" -- dnf install -y rpkg
    buildah run "$bcont" -- dnf clean all
fi

if ! buildah run "$bcont" test -d /rpmbuild; then
    buildah run "$bcont" -- mkdir -p /rpmbuild
    buildah run "$bcont" -- chown $uid:$uid /rpmbuild
fi

buildah config --user "$uid" "$bcont"
buildah config --workingdir /var/tmp/source "$bcont"
buildah commit "$bcont" "$image_name"

echo "image: $image_name"
