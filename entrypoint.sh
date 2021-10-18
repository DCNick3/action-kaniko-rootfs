#!/busybox/sh
set -e pipefail

export REGISTRY=${INPUT_REGISTRY:-"docker.pkg.github.com"}
export IMAGE=${INPUT_IMAGE}
export BRANCH=$(echo ${GITHUB_REF} | sed -E "s/refs\/(heads|tags)\///g" | sed -e "s/\//-/g")
export USERNAME=${INPUT_USERNAME:-$GITHUB_ACTOR}
export PASSWORD=${INPUT_PASSWORD:-$GITHUB_TOKEN}
export REPOSITORY=$IMAGE
export CONTEXT_PATH=${INPUT_PATH}
export INPUT_CACHE_REGISTRY=${INPUT_CACHE_REGISTRY:cache}
export ROOTFS_PATH=${INPUT_ROOTFS_PATH}

function ensure() {
    if [ -z "${1}" ]; then
        echo >&2 "Unable to find the ${2} variable. Did you set with.${2}?"
        exit 1
    fi
}

ensure "${REGISTRY}" "registry"
ensure "${USERNAME}" "username"
ensure "${PASSWORD}" "password"
ensure "${IMAGE}" "image"
ensure "${CONTEXT_PATH}" "path"
ensure "${ROOTFS_PATH}" "rootfs_path"

if [ "$REGISTRY" == "docker.pkg.github.com" ]; then
    IMAGE_NAMESPACE="$(echo $GITHUB_REPOSITORY | tr '[:upper:]' '[:lower:]')"
    if [ ! -z $INPUT_CACHE_REGISTRY ]; then
        export INPUT_CACHE_REGISTRY="$REGISTRY/$IMAGE_NAMESPACE/$INPUT_CACHE_REGISTRY"
    fi
fi

export CACHE=${INPUT_CACHE:+"--cache=true"}
export CACHE=$CACHE${INPUT_CACHE_TTL:+" --cache-ttl=$INPUT_CACHE_TTL"}
export CACHE=$CACHE${INPUT_CACHE_REGISTRY:+" --cache-repo=$INPUT_CACHE_REGISTRY"}
export CACHE=$CACHE${INPUT_CACHE_DIRECTORY:+" --cache-dir=$INPUT_CACHE_DIRECTORY"}
export CONTEXT="--context $GITHUB_WORKSPACE/$CONTEXT_PATH"
export DOCKERFILE="--dockerfile $CONTEXT_PATH/${INPUT_BUILD_FILE:-Dockerfile}"
export TARGET=${INPUT_TARGET:+"--target=$INPUT_TARGET"}
export DESTINATION="--no-push --tarPath image.tar --destination $IMAGE"

export ARGS="$CACHE $CONTEXT $DOCKERFILE $TARGET $DESTINATION $INPUT_EXTRA_ARGS"

cat <<EOF >/kaniko/.docker/config.json
{
    "auths": {
        "https://${REGISTRY}": {
            "username": "${USERNAME}",
            "password": "${PASSWORD}"
        }
    }
}
EOF

# https://github.com/GoogleContainerTools/kaniko/issues/1349
/kaniko/executor --reproducible --force $ARGS
/kaniko/undocker image.tar - | gzip -9 > $ROOTFS_PATH
