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
 * Build a Docker container for JOD
 * TODO: Description
 * 
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
 * Build a Docker container for JOD
 * TODO: Description
 *
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

// process pullXlsx2owlImage {
//     beforeScript "docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY"

//     input:
//         val buildDockerContainer_done
//     output:
//         val "" into pullXlsx2owlImage_done
//     """
//     #!/usr/bin/env bash
    
//     docker pull "git.infai.org:4567/materialdigital/stahldigital/xlsx2owl-stahl:latest"
//     """

// }

// process xlsx2owl {
//     container 'git.infai.org:4567/materialdigital/stahldigital/xlsx2owl-stahl:latest'
//     beforeScript "chmod a+w ."
//     echo true
//     stageInMode "copy"
//     stageOutMode "copy"
//     input:
//         val pullXlsx2owlImage_done
// //     	path input from "$projectDir/xlsx2owl-StahlDigital.xlsx"

//     output:
//         path "StahlDigital-vocab.ttl" into ttl
// 	val "" into xlsx2owl_done

//     """
//     export processDir=\$(pwd)
//     cd /home/user/
//     bash -x "/home/user/xlsx2owl-StahlDigital.sh" "https://files.iis.aksw.org/s/Pj2ZC9WRNMgJMrx/download/CI_MOCK_DATA.xlsx"
//     cp StahlDigital-vocab.ttl \$processDir
//     cp StahlDigital-vocab.nq \$processDir
//     """
// }

// process pullJodImage {
//     beforeScript "docker login -u $CI_REGISTRY_USER -p $CI_JOD_TOKEN $CI_REGISTRY"

//     input:
//         val xlsx2owl_done
//     output:
//         val "" into pullJodImage_done

//     """
//     docker pull "git.infai.org:4567/materialdigital/stahldigital/jod-for-stahl:latest"
//     """

// }

// process jod {
//     container 'git.infai.org:4567/materialdigital/stahldigital/jod-for-stahl:latest'
//     beforeScript "chmod a+w ."
//     echo true
//     stageInMode "copy"
//     stageOutMode "copy"
//     publishDir '.', mode: 'copy'
//     input:
//     	path ttl
//     output:
//         path "_site/*" into site

//     """
//     run_all.sh
//     """
// }
