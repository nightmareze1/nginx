#!/usr/bin/env groovy

import groovy.json.JsonOutput
import java.util.Optional

def notifySlack(text, channel, attachments) {

    //your  slack integration url
    def slackURL = 'https://hooks.slack.com/services/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' 
    //from the jenkins wiki, you can updload an avatar and
    //use that one
    def jenkinsIcon = 'https://wiki.jenkins-ci.org/download/attachments/2916393/logo.png'
    
    def payload = JsonOutput.toJson([text      : text,
                                     channel   : channel,
                                     username  : "jenkins",
                                     icon_url: jenkinsIcon,
                                     attachments: attachments])
                                     
    sh "curl -X POST --data-urlencode \'payload=${payload}\' ${slackURL}"
}

podTemplate(label: 'template', containers: [
    containerTemplate(name: 'docker', image: 'docker', ttyEnabled: true, command: 'cat'),
    containerTemplate(name: 'kubectl', image: 'lachlanevenson/k8s-kubectl:v1.8.0', command: 'cat', ttyEnabled: true),
    containerTemplate(name: 'curl', image: 'tutum/curl:latest', command: 'cat', ttyEnabled: true),
    containerTemplate(name: 'helm', image: 'lachlanevenson/k8s-helm:v2.10.0-rc.3', command: 'cat', ttyEnabled: true)
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
        def slackNotificationChannel = 'random'
    //this try if for build failures
    try {
        container('curl') {
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
                        sh "docker images"
                        sh "docker rmi -f ${DOCKER_HUB_USER}/nginx:v0.0.${env.BUILD_NUMBER}"
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
                            docker run -i --rm ${DOCKER_HUB_USER}/nginx:v0.0.${env.BUILD_NUMBER} ls -la /usr/share/nginx/html  
                            docker rmi -f ${DOCKER_HUB_USER}/nginx:v0.0.${env.BUILD_NUMBER}
                            """
                    }
                }
            }
            stage('kubernetes deploy stg') {
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
                            sed -i "s/<VERSION>/v0.0.${env.BUILD_NUMBER}/" template/deployment.yml
                            sed -i "s/<REPO>/nightmareze1/" template/deployment.yml
                            sed -i "s/<PROJECT>/nginx/" template/deployment.yml
                            """
                        sh """
                            cat template/deployment.yml
                            cat template/svc.yml
                            cat template/ing.yml
                            kubectl apply -f template/deployment.yml
                            kubectl apply -f template/svc.yml
                            kubectl apply -f template/ing.yml
                            """
                    }
                }
            }        
            stage('helm packet') {
                container('helm') {
			
	           sh "ls"
                }
            }
        def buildColor = currentBuild.result == null? "good": "warning"
        def buildStatus = currentBuild.result == null? "Success": currentBuild.result
        //configure emoji, because that's what millenials do
        def buildEmoji = currentBuild.result == null? ":smiley:":":cold_sweat:"

        notifySlack("${buildStatus}", "random",
            [[
            title: "nginx-success build and deploy in [STG] nightmareze1/nginx:v0.0.${env.BUILD_NUMBER}",
                color: "good",
                text: """${buildEmoji} Build ${buildStatus}. 
                |${env.BUILD_URL}
                |branch: ${env.BRANCH_NAME}""".stripMargin()
            ]])
        }

    } 
    catch (e) {
            container('curl') {
                //modify #build-channel to the build channel you want
                //for public channels don't forget the # (hash)
                notifySlack("build failed", "random",
                    [[
                        title: "nginx-failed in build process and has not been implemented in [STG] nightmareze1/nginx:v0.0.${env.BUILD_NUMBER}",
                        color: "danger",
                        text: """:dizzy_face: Build finished with error. 
                        |${env.BUILD_URL}
                        |branch: ${env.BRANCH_NAME}""".stripMargin()
                    ]])
                throw e
            }
        }
            stage('Deploy to [PRD]') {
                container('curl') {
 	          echo ""
		  echo ""
		  echo "A continuacion seleccione si quiere deployar a PRD"
                }
            }
	    timeout(time: 30, unit: 'SECONDS') {
     	    def userInput = input(
             id: 'Proceed1', message: 'Desea deployar en [PRD]?', parameters: [
            ])
	    }
    try {
        container('curl') {
            stage('kubernetes deploy prd') {
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
                            sed -i "s/<VERSION>/v0.0.${env.BUILD_NUMBER}/" template/deployment.yml
                            sed -i "s/<REPO>/nightmareze1/" template/deployment.yml
                            sed -i "s/<PROJECT>/nginx/" template/deployment.yml
                            """
                        sh """
                            cat template/deployment.yml
                            cat template/svc.yml
                            cat template/ing.yml
                            kubectl apply -f template/deployment.yml
                            kubectl apply -f template/svc.yml
                            kubectl apply -f template/ing.yml
                            """
                    }
                }
            }
        def buildColor = currentBuild.result == null? "good": "warning"
        def buildStatus = currentBuild.result == null? "Success": currentBuild.result
        //configure emoji, because that's what millenials do
        def buildEmoji = currentBuild.result == null? ":smiley:":":cold_sweat:"

        notifySlack("${buildStatus}", "random",
            [[
            title: "nginx-success deployment [PRD] nightmareze1/nginx:v0.0.${env.BUILD_NUMBER}",
                color: "good",
                text: """${buildEmoji} Build ${buildStatus}. 
                |${env.BUILD_URL}
                |branch: ${env.BRANCH_NAME}""".stripMargin()
            ]])
        }
        } catch (err) {  // input false
            container('curl') {
                //modify #build-channel to the build channel you want
                //for public channels don't forget the # (hash)
                notifySlack("build failed", "random",
                    [[
                        title: "nginx-failed deployment [PRD] nightmareze1/nginx:v0.0.${env.BUILD_NUMBER}",
                        color: "danger",
                        text: """:dizzy_face: Build finished with error. 
                        |${env.BUILD_URL}
                        |branch: ${env.BRANCH_NAME}""".stripMargin()
                    ]])
                throw err
            }
          def user = err.getCauses()[0].getUser(i)
          userInput = false
          echo "Aborted by: [${user}]"
        }
    }
}
