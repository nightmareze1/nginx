pipeline {
    agent any
    environment {
        PRIVATE_REPO = "${PRIVATE_REGISTRY}/${REPO}"
        DOCKER_PRIVATE = credentials('docker-private-registry')
    }
    stages {
        stage ('Checkout') {
            steps {
                script {
		   COMMIT1 = "${GIT_COMMIT.substring(0,8)}"
                   echo "${COMMIT1}"
                   TAG   = "latest"
                   NGINX = "alpine"
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
                        sh "docker build -f nginx/Dockerfile -t ${REPO}:${COMMIT1}-nginx nginx/"
                    }
                    post {
                        success {
                            echo 'Tag for private registry'
                            sh "docker tag ${REPO}:${COMMIT1}-nginx ${PRIVATE_REPO}:${NGINX}"
                        }
                    }
                }
               
            }
        }
    }    
}
