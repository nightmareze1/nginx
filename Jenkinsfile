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
 
        stage('build') {
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
        stage('Testing Docker') {
            container('docker') {

                withCredentials([[$class: 'UsernamePasswordMultiBinding',
                        credentialsId: 'dockerhub',
                        usernameVariable: 'DOCKER_HUB_USER',
                        passwordVariable: 'DOCKER_HUB_PASSWORD']]) {

                    sh """
                        docker run -i --rm ${DOCKER_HUB_USER}/nginx:v0.0.${env.BUILD_NUMBER} ls -la 
                        docker rmi -f ${DOCKER_HUB_USER}/nginx:v0.0.${env.BUILD_NUMBER}
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
                    sh """
                        pwd > path.txt
                        ls -la >> path.txt
                        cat path.txt
                        sed -i "s/<VERSION>/v0.0.${env.BUILD_NUMBER}/g" template/deployment.yml
                        sed -i "s/<REPO>/${DOCKER_HUB_USER}/g" template/deployment.yml
                        sed -i "s/<PROJECT>/nginx/g" template/deployment.yml
                        """
                    sh """
                        kubectl apply -f template/deployment.yml
                        kubectl apply -f template/svc.yml
                        kubectl apply -f template/ing.yml
                        """
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
