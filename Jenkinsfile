pipeline {
    agent any
    environment {
        REPO = 'nightmareze1/alpine/'
        PRIVATE_REPO = "${PRIVATE_REGISTRY}/${REPO}"
        DOCKER_PRIVATE = credentials('docker-private-registry')
    }
    stages {
        stage ('Checkout') {
            steps {
                script {
                    echo $REPO
                    echo $PRIVATE_REPO
                    echo $DOCKER_PRIVATE
                    echo "${GIT_COMMIT.substring(0,8)}"
                    COMMIT = "${GIT_COMMIT.substring(0,8)}"

                    if ("${BRANCH_NAME}" == "master"){
                        TAG   = "latest"
                        NGINX = "alpine"
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
                        sh "docker build -f nginx/Dockerfile -t ${REPO}:${COMMIT}-nginx nginx/"
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
    }    
}
