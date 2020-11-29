#!groovy

pipeline {
    agent any
    environment {
        BUILD_DATE = sh(returnStdout: true, script: "date -u +'%d-%m-%Y-%H-%M-%S'").trim()
    }
    options {
        skipDefaultCheckout()
        disableConcurrentBuilds()
    }
    
    stages {
        stage('Clone repository') {
            steps {
                git 'https://github.com/nobumori/devops-training-project-frontend.git'
            }
        }
        stage('Replace backend URL') {
            steps {
                sh "sed -i 's/conduit.productionready.io\\/api/localhost\\:8080/g' src/agent.js"
            }
        }
        stage('Sonarqube'){
            when {
                branch 'develop'
            }
            environment {
                scannerHome = tool 'sonarqube_scaner'
            }
            steps {
                withSonarQubeEnv('sonarqube') {
                     sh "${scannerHome}/bin/sonar-scanner -Dsonar.projectKey=frontend_dev -Dsonar.sources=."
                }
            }
        }
        stage("Quality Gate") {
            when {
                branch 'develop'
            }
            steps {
                sleep(5)
                timeout(time: 3, unit: 'MINUTES') {
                    script  {
                        def qg = waitForQualityGate()
                        if (qg.status != 'OK') {
                            error "Pipeline aborted due to quality gate failure: ${qg.status}"
                        }
                    }
                }
            }
        }
        stage('Build') {
            steps {
                sh "npm install"
                sh "npm run build"
            }
        }
        stage('Push to Nexus') {
            steps {
                sh "zip -r build-${BUILD_ID}.zip build/*"
                script {
                    dir('.') {
                    def artifact_name = "build-${BUILD_ID}"
                    nexusArtifactUploader artifacts: [[artifactId: 'build', file: "${artifact_name}.zip", type: 'zip']],
                        credentialsId: 'jenkins',
                        groupId: 'devops-training',
                        nexusUrl: '${NEXUS_URL}',
                        nexusVersion: 'nexus3',
                        protocol: 'https',
                        repository: '${NEXUS_FRONT}',
                        version: "$BUILD_DATE"
                    }
                }    
            }
        }
        stage ('Delpoy Ansible') {
            environment {
                ARTIFACT_URL = 'https://${NEXUS_URL}/repository/frontend/devops-training/build/$BUILD_DATE/build-$BUILD_DATE.zip'
            }
            steps{
                sh "ansible-playbook app_front.yml --extra-vars nexus_front_url=$ARTIFACT_URL"
            }
        }
    }
    post {
 //       always {
 //           cleanWs()
 //       }
        success{
            echo " ---=== SUCCESS ===---"
        }
        failure{
            echo " ---=== FAILURE ===---"
        }
    }
}
