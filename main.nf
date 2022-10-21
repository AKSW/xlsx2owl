#!/usr/bin/env nextflow

CI_REGISTRY_PASSWORD = System.getenv("CI_REGISTRY_PASSWORD") ?: ""
params.push = ""

if (!CI_REGISTRY_PASSWORD) {
  print("Running locally")
  if (params.push) {
    evaluate(new File("secrets"))
  }
  CI_REGISTRY_USER = "bot"
  registryPort="4567"
  repoURL="git remote get-url origin".execute().text.strip()
  CI_REGISTRY = "git.infai.org:4567"
  CI_COMMIT_BRANCH = "git rev-parse --abbrev-ref HEAD".execute().text.strip()
  CI_DEFAULT_BRANCH = "main"
  CI_COMMIT_REF_SLUG = "$CI_COMMIT_BRANCH"
  matcher = repoURL =~ /(git@|https:\/\/)(?<domain>[\w.]+)[:\/](?<path>.*)\.git/
  matcher.matches()
  CI_REGISTRY_IMAGE = /${matcher.group('domain')}:$registryPort\/${matcher.group('path')}/
}

/*
 * Build a Docker image
 */

process buildImage {
    output:
      val "" into buildImage
      env tag optional true into tag

    """
    #!/usr/bin/env bash

    cd $projectDir

    if [[ "$CI_COMMIT_BRANCH" == "$CI_DEFAULT_BRANCH" ]]; then
        tag=""
        echo "Running on default branch "$CI_DEFAULT_BRANCH": tag = "latest""
    else
        tag=":$CI_COMMIT_REF_SLUG"
        echo "Running on branch "$CI_COMMIT_BRANCH": tag = \$tag"
    fi

    docker build --pull -t "$CI_REGISTRY_IMAGE\${tag}" .

    cd -
    """
}

process TODO_testImage {
    input:
      val buildImage
      val tag from tag.ifEmpty('')
    output:
      val "" into testImage

    """
    #!/usr/bin/env bash

    echo ""
    """
}

/*
 * Push Docker image to registry
 */

process pushImage {
    beforeScript "docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY"

    input:
      val testImage
      val tag from tag.ifEmpty('')

    when:
  params.push

    """
    #!/usr/bin/env bash

    docker push "$CI_REGISTRY_IMAGE${tag}"
    """
}
