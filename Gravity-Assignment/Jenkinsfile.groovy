pipeline {
    agent any

    environment {
        PROJECT_ID = 'your-project-id'
        ZONE = 'us-central1-a'
        INSTANCE_NAME = 'my-instance'
        SSH_CREDENTIALS_ID = 'gce-ssh-key'  
    }
// Or we cant set environment variable in click Manage Jenkins > Manage Credentials>
    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/your-repo.git'
            }
        }

        stage('Build') {
            steps {
                sh 'echo "Building application..."'
                // Add your build commands here, e.g., for a Node.js app:
                // sh 'npm install'
            }
        }

        stage('Test') {
            steps {
                sh 'echo "Running tests..."'
                // Add your test commands here, e.g., for a Node.js app:
                // sh 'npm test'
            }
        }

        stage('Deploy') {
            steps {
                sshagent(credentials: [env.SSH_CREDENTIALS_ID]) {
                    sh """
                        echo "Deploying application to GCE instance..."
                        gcloud compute scp --zone=${env.ZONE} --recurse * ${env.INSTANCE_NAME}:/var/www/html/
                        gcloud compute ssh --zone=${env.ZONE} ${env.INSTANCE_NAME} --command='sudo systemctl restart nginx'
                    """
                }
            }
        }
    }

    post {
        success {
            echo 'Deployment successful!'
        }
        failure {
            echo 'Deployment failed.'
        }
    }
}
