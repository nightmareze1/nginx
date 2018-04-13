pipeline {
    agent any
    environment {
        REPO = 'nightmareze1/nginx'
        PRIVATE_REPO = "${PRIVATE_REGISTRY}/${REPO}"
        DOCKER_PRIVATE = credentials('docker-private-registry')
    }
    stages {
        stage ('Checkout') {
            steps {
                script {
                    COMMIT = "${GIT_COMMIT.substring(0,8)}"

                    if ("${BRANCH_NAME}" == "master"){
                        TAG   = "latest"
                        NGINX = "nginx"
                    }
                    else {
                        TAG   = "${BRANCH_NAME}"
                        NGINX = "${BRANCH_NAME}-nginx"                   
                    }
                }
                sh 'printenv'
            }
        }
        stage ('Docker build Micro-Service') {
            parallel {
                stage ('Wodpress Nginx'){
                    agent { label 'jenkins-slave'}
                    steps {
                        sh "docker build -f Dockerfile -t ${REPO}:${COMMIT}-nginx ."
                    }
                    post {
                        success {
                            echo 'Tag for private registry'
                            sh "docker tag ${REPO}:${COMMIT}-nginx ${PRIVATE_REPO}:${NGINX}"
                        }
                    }
                }

            }
        }
        stage ('Run'){
            parallel {
                stage ('Micro-Services'){
                    agent { label 'docker'}
                    steps {
                        // Create Network
                        sh "docker network create wordpress-micro-${BUILD_NUMBER}"
                        sh "docker run -d --name 'nginx-${BUILD_NUMBER}' --network wordpress-micro-${BUILD_NUMBER} ${REPO}:${COMMIT}-nginx"
                        // Get container IDs
                        script {
                            DOCKER_NGINX = sh(script: "docker ps -qa -f ancestor=${REPO}:${COMMIT}-nginx", returnStdout: true).trim()
                        }
                    }
                }
            }
        }
        stage ('Test'){
            parallel {
                stage ('Micro-Services'){
                    agent { label 'jenkins-slave'}
                    steps {
                        sleep 20
                        sh "docker logs nginx-${BUILD_NUMBER}"
                        // External
                        sh "docker run --rm --network wordpress-micro-${BUILD_NUMBER} blitznote/debootstrap-amd64:17.04 bash -c 'curl -iL -X GET http://${DOCKER_NGINX}:80'"
                    }
                    post {
                        always {
                            echo 'Remove micro-services stack'

                            sh "docker rm -fv nginx-${BUILD_NUMBER}"
                            sleep 10
                            sh "docker network rm wordpress-micro-${BUILD_NUMBER}"
                        }
                        success {
                            sh "docker login -u ${DOCKER_PRIVATE_USR} -p ${DOCKER_PRIVATE_PSW} ${PRIVATE_REGISTRY}"
                            sh "docker push ${PRIVATE_REPO}:${NGINX}"
                        }
                    }
                }
            }
        }
    }
    post {
        always {
            echo 'Run regardless of the completion status of the Pipeline run.'
        }
        changed {
            echo 'Only run if the current Pipeline run has a different status from the previously completed Pipeline.'
        }
        success {
            echo 'Only run if the current Pipeline has a "success" status, typically denoted in the web UI with a blue or green indication.'

        }
        unstable {
            echo 'Only run if the current Pipeline has an "unstable" status, usually caused by test failures, code violations, etc. Typically denoted in the web UI with a yellow indication.'
        }
        aborted {
            echo 'Only run if the current Pipeline has an "aborted" status, usually due to the Pipeline being manually aborted. Typically denoted in the web UI with a gray indication.'
        }
    }
}
