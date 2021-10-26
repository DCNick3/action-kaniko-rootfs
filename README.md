# Kaniko image builder

This action allows you to build a docker container and extract its rootfs. This action is based on aevea's [action-kaniko](https://github.com/aevea/action-kaniko).

## Usage

## Example pipeline
```yaml
name: Docker build
on: push
jobs:
  docker:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@master
      - name: Kaniko build
        uses: DCNick3/action-kaniko-rootfs@master
        with:
          password: ${{ secrets.GITHUB_TOKEN }}
          cache: true
```

## Required Arguments

| variable         | description                                              | required | default                     |
|------------------|----------------------------------------------------------|----------|-----------------------------|
| rootfs_path      | Path to which to put the resulting rootfs .tar.gz        | true     |                             |

## Optional Arguments

| variable              | description                                                     | required | default         |
|-----------------------|-----------------------------------------------------------------|----------|-----------------|
| registry              | Docker registry where the cache will be pushed                  | false    | docker.io       |
| cache_registry        | Docker registry image name to be used as cache                  | false    | cache           |
| username              | Username used for authentication to the Docker registry         | false    | $GITHUB_ACTOR   |
| password              | Password used for authentication to the Docker registry         | false    |                 |
| cache                 | Enables build cache                                             | false    | false           |
| cache_ttl             | How long the cache should be considered valid                   | false    |                 |
| cache_directory       | Filesystem path meant to be used as cache                       | false    |                 |
| build_file            | Dockerfile filename                                             | false    | Dockerfile      |
| extra_args            | Additional arguments to be passed to the kaniko executor        | false    |                 |
| path                  | Path to the build context. Defaults to `.`                      | false    | .               |
| target                | Sets the target stage to build                                  | false    |                 |

**Here is where it gets specific, as the optional arguments become required depending on the registry targeted**

### [docker.pkg.github.com](https://github.com/features/packages)

GitHub's docker registry is a bit special. It doesn't allow top-level images, so this action will prefix any image with the GitHub namespace.
If you want to push your image like `aevea/action-kaniko/kaniko`, you'll only need to pass `kaniko` to this action.

The authentication is automatically done using the `GITHUB_ACTOR` and `GITHUB_TOKEN` provided from GitHub itself. But as `GITHUB_TOKEN` is not
passed by default, it will have to be explicitly set up.

```yaml
with:
  registry: docker.pkg.github.com
  password: ${{ secrets.GITHUB_TOKEN }}
  image: kaniko
```

> NOTE: GitHub's docker registry is structured a bit differently, but it has the same drawback as Dockerhub, and that's that it's not possible
to "namespace" images for cache. In order to use registry cache, just specify the image meant to be used as cache, and Kaniko will push the
cache layers to that image instead

```yaml
with:
  registry: docker.pkg.github.com
  password: ${{ secrets.GITHUB_TOKEN }}
  image: kaniko
  cache: true
  cache_registry: cache
```

### [registry.gitlab.com](https://docs.gitlab.com/ee/user/packages/container_registry)

GitLab's registry is quite flexible, it allows easy image namespacing, so a project's docker registry can hold up to three levels of image
repository names.

```
registry.gitlab.com/group/project:some-tag
registry.gitlab.com/group/project/image:latest
registry.gitlab.com/group/project/my/image:rc1
```

To authenticate to it, a username and personal access token must be supplied via GitHub Action Secrets.

```yaml
with:
  registry: registry.gitlab.com
  username: ${{ secrets.GL_REGISTRY_USERNAME }}
  password: ${{ secrets.GL_REGISTRY_PASSWORD }}
  image: aevea/kaniko
```

> NOTE: As GitLab's registry does support namespacing, Kaniko can natively push cached layers to it, so only `cache: true` is necessary to be
specified in order to use it.

```yaml
with:
  registry: registry.gitlab.com
  username: ${{ secrets.GL_REGISTRY_USERNAME }}
  password: ${{ secrets.GL_REGISTRY_PASSWORD }}
  image: aevea/kaniko
  cache: true
```

### Other registries

If you would like to publish the image to other registries, these actions might be helpful

| Registry                                             | Action                                        |
|------------------------------------------------------|-----------------------------------------------|
| Amazon Webservices Elastic Container Registry (ECR)  | https://github.com/elgohr/ecr-login-action    |
| Google Cloud Container Registry                      | https://github.com/elgohr/gcloud-login-action |
