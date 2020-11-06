#!groovy

pipeline {
    agent any
    parameters {
        string(name: 'commit_id', defaultValue: 'develop', description: 'branch/tag/commit value to deploy')
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
                sh "sed -i 's/conduit.productionready.io\\/api/backend.okurnitsov.test.coherentprojects.net/g' src/agent.js"
            }
        }
        stage('Sonarqube'){
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
            steps {
                sleep(5)
                timeout(time: 3, unit: 'MINUTES') {
                    script  {
                        def qg = waitForQualityGate()
                        if (qg.status != 'SUCCESS') {
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
            environment {
                BUILD_DATE = sh(returnStdout: true, script: "date -u +'%d_%m_%Y_%H_%M_%S'").trim()
            }
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
                        version: "${BUILD_DATE}"
                    }
                }    
            }
        }
    }
    post {
        always {
            cleanWs()
        }
        success{
            echo " ---=== SUCCESS ===---"
        }
        failure{
            echo " ---=== FAILURE ===---"
        }
    }
}