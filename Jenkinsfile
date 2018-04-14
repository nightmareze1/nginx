podTemplate(label: 'mypod', containers: [
    containerTemplate(name: 'docker', image: 'docker', ttyEnabled: true, command: 'cat'),
    containerTemplate(name: 'kubectl', image: 'lachlanevenson/k8s-kubectl:v1.8.0', command: 'cat', ttyEnabled: true),
    containerTemplate(name: 'helm', image: 'lachlanevenson/k8s-helm:latest', command: 'cat', ttyEnabled: true)
  ],
  volumes: [
    hostPathVolume(mountPath: '/var/run/docker.sock', hostPath: '/var/run/docker.sock'),
  ]) {
    node('mypod') {

        stage('do some Docker work') {
            container('docker') {

                withCredentials([[$class: 'UsernamePasswordMultiBinding', 
                        credentialsId: 'docker-private-registry',
                        usernameVariable: 'DOCKER_HUB_USER', 
                        passwordVariable: 'DOCKER_HUB_PASSWORD']]) {
                    
                    sh """
                        printenv
                        docker pull ubuntu
                        docker tag ubuntu nightmareze1/ubuntu:${env.BUILD_NUMBER}
                        """
                    sh "docker login -u ${env.DOCKER_HUB_USER} -p 3da2a54280a9c894fb551c3bc4659dfe https://index.docker.io/v1"
                    sh "docker push ${env.DOCKER_HUB_USER}/ubuntu:${env.BUILD_NUMBER} "
                }
            }
        }

        stage('do some kubectl work') {
            container('kubectl') {

                withCredentials([[$class: 'UsernamePasswordMultiBinding', 
                        credentialsId: 'dockerhub',
                        usernameVariable: 'DOCKER_HUB_USER',
                        passwordVariable: 'DOCKER_HUB_PASSWORD']]) {
                    
                    sh "kubectl get nodes"
                }
            }
        }
        stage('do some helm work') {
            container('helm') {

               sh "helm ls"
            }
        }
    }
}
