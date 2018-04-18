podTemplate(label: 'template', containers: [
    containerTemplate(name: 'docker', image: 'docker', ttyEnabled: true, command: 'cat'),
    containerTemplate(name: 'kubectl', image: 'lachlanevenson/k8s-kubectl:v1.8.0', command: 'cat', ttyEnabled: true),
    containerTemplate(name: 'helm', image: 'lachlanevenson/k8s-helm:latest', command: 'cat', ttyEnabled: true)
  ],
  volumes: [
    hostPathVolume(mountPath: '/var/run/docker.sock', hostPath: '/var/run/docker.sock'),
  ]) {
    node('template') {
        def myRepo = checkout scm
        def gitCommit = myRepo.GIT_COMMIT
        def gitBranch = myRepo.GIT_BRANCH
        def shortGitCommit = "${gitCommit[0..10]}"
        def previousGitCommit = sh(script: "git rev-parse ${gitCommit}~", returnStdout: true)
 
    stages {
        stage('build') {
            steps {  
                container('docker') {

                    withCredentials([[$class: 'UsernamePasswordMultiBinding', 
                            credentialsId: 'dockerhub',
                            usernameVariable: 'DOCKER_HUB_USER', 
                            passwordVariable: 'DOCKER_HUB_PASSWORD']]) {
                       
                        sh """
                            printenv
                            pwd
                            echo "GIT_BRANCH=${gitBranch}" >> /etc/environment
                            echo "GIT_COMMIT=${gitCommit}" >> /etc/environment
                            cat /etc/environment
                            cat Dockerfile
                            docker build -f Dockerfile -t ${DOCKER_HUB_USER}/nginx:v0.0.${env.BUILD_NUMBER} .
                            """
                        sh "docker login -u ${DOCKER_HUB_USER} -p ${DOCKER_HUB_PASSWORD} "
                        sh "docker push ${DOCKER_HUB_USER}/nginx:v0.0.${env.BUILD_NUMBER}"
                    }
                }    
            }
        }
        stage('Testing Docker') {
            steps { 
                container('docker') {

                    withCredentials([[$class: 'UsernamePasswordMultiBinding',
                            credentialsId: 'dockerhub',
                            usernameVariable: 'DOCKER_HUB_USER',
                            passwordVariable: 'DOCKER_HUB_PASSWORD']]) {

                        sh """
                            docker run -i --rm ${DOCKER_HUB_USER}/nginx:v0.0.${env.BUILD_NUMBER} ls -la /usr/share/nginx/html 
                            docker rmi -f ${DOCKER_HUB_USER}/nginx:v0.0.${env.BUILD_NUMBER}
                    """
                    }
                }
            }
        }
        stage('helm packet') {
            steps { 
                container('helm') {

                   sh "helm ls"
                }
            }
        }
    }
}
