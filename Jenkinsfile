pipeline {
    agent {
        kubernetes {
            label 'helm'
        }
    }
    stages {
        stage('Test') {
            steps {
                container('chart-testing') {
                    sh "chart_test.sh --no-install --all"
                }
            }
        }
        stage('Package') {
            steps {
                container('chart-testing'){
                    sh 'mkdir target'
                    sh 'for dir in charts/*; do helm package --destination target "$dir"; done'
                }
            }
        }
        stage('Deploy') {
            when {
                branch 'master'
            }
            steps {
                container('vault') {
                    script {
                        env.NEXUS_USER = sh(script: 'vault read -field=username secret/ops/account/nexus', returnStdout: true)
                        env.NEXUS_PWD = sh(script: 'vault read -field=password secret/ops/account/nexus', returnStdout: true)
                    }
                }
                container('alpine') {
                    sh 'set +x; for chart in target/*; do curl -L -u $NEXUS_USER:$NEXUS_PWD http://registry.molgenis.org/repository/helm/ --upload-file "$chart"; done'
                }
            }
        }
    }
}