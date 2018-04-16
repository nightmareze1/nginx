podTemplate(label: 'template', containers: [
    containerTemplate(name: 'docker', image: 'docker', ttyEnabled: true, command: 'cat'),
    containerTemplate(name: 'kubectl', image: 'lachlanevenson/k8s-kubectl:v1.8.0', command: 'cat', ttyEnabled: true),
    containerTemplate(name: 'helm', image: 'lachlanevenson/k8s-helm:latest', command: 'cat', ttyEnabled: true)
  ],
  volumes: [
    hostPathVolume(mountPath: '/var/run/docker.sock', hostPath: '/var/run/docker.sock'),
  ]) {
    node('template') {
        
        stage('build') {
            container('docker') {

                withCredentials([[$class: 'UsernamePasswordMultiBinding', 
                        credentialsId: 'dockerhub',
                        usernameVariable: 'DOCKER_HUB_USER', 
                        passwordVariable: 'DOCKER_HUB_PASSWORD']]) {
                    
                    sh """
                        printenv
                        cd ${WORKSPACE}@tmp
                        pwd
                        ls -la > a.txt
                        cat a.txt
                        cat Dockerfile
                        docker build -f Dockerfile -t ${DOCKER_HUB_USER}/v.0.0.${env.BUILD_NUMBER} .
                        """
                    sh "docker login -u ${DOCKER_HUB_USER} -p ${DOCKER_HUB_PASSWORD} "
                    sh "docker push ${DOCKER_HUB_USER}/v.0.0.${env.BUILD_NUMBER}"
                }
            }
        }
        stage('Testing Docker') {
            container('docker') {

                withCredentials([[$class: 'UsernamePasswordMultiBinding',
                        credentialsId: 'dockerhub',
                        usernameVariable: 'DOCKER_HUB_USER',
                        passwordVariable: 'DOCKER_HUB_PASSWORD']]) {

                    sh """
                        docker pull ${DOCKER_HUB_USER}/v.0.0.${env.BUILD_NUMBER}
                        docker run -i --rm ${DOCKER_HUB_USER}/v.0.0.${env.BUILD_NUMBER} apt-get update && apt-get install curl -y && curl http://localhost 
                        docker rmi -f ${DOCKER_HUB_USER}/v.0.0.${env.BUILD_NUMBER}
		        """
                }
            }
        }
        stage('kubernetes deploy') {
            container('kubectl') {

                withCredentials([[$class: 'UsernamePasswordMultiBinding', 
                        credentialsId: 'docker-private-registry',
                        usernameVariable: 'DOCKER_HUB_USER',
                        passwordVariable: 'DOCKER_HUB_PASSWORD']]) {
                    
                    sh "kubectl get nodes"
                }
            }
        }
        stage('helm packet') {
            container('helm') {

               sh "helm ls"
            }
        }
    }
}
