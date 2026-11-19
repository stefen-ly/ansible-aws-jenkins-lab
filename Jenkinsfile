
pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        LAB_DIR = '/home/ubuntu/IaC_Lab/lab2'
        DOCKERHUB_USER = 'stefenly19'
    }

    stages {
        stage('1. Git Checkout') {
            steps {
                checkout scm
                sh 'git log -1 --oneline'
            }
        }

        stage('2. Validate Ansible') {
            steps {
                dir("${LAB_DIR}") {
                    sh '''
                        set -e
                        ansible-playbook \
                          playbook/fileupload-main.yaml \
                          --syntax-check

                        ansible-inventory \
                          -i inventory.ini --graph
                    '''
                }
            }
        }

        stage('3. Build & Push Docker Image') {
            steps {
                dir("${LAB_DIR}") {
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'dockerhub-credentials',
                            usernameVariable: 'DOCKER_USER',
                            passwordVariable: 'DOCKER_TOKEN'
                        )
                    ]) {
                        sh '''
                            set +x
                            set -e

                            export DOCKER_CONFIG="$(mktemp -d)"
                            trap 'rm -rf "$DOCKER_CONFIG"' EXIT

                            printf '%s' "$DOCKER_TOKEN" |
                              docker login \
                                -u "$DOCKER_USER" \
                                --password-stdin

                            ansible-playbook \
                              -i inventory.ini \
                              playbook/fileupload-build.yaml \
                              -e "dockerhub_user=$DOCKER_USER"
                        '''
                    }
                }
            }
        }

        stage('4. Deploy to AWS EC2') {
            steps {
                dir("${LAB_DIR}") {
                    sshagent(credentials: ['lab2-ssh-key']) {
                        sh '''
                            set -e
                            ansible-playbook \
                              -i inventory.ini \
                              playbook/fileupload-deploy.yaml \
                              -e "dockerhub_user=$DOCKERHUB_USER" \
                              -e 'ansible_ssh_private_key_file=' \
                              -e 'ansible_ssh_common_args=-o IdentitiesOnly=no'
                        '''
                    }
                }
            }
        }

        stage('5. Verify Containers') {
            steps {
                dir("${LAB_DIR}") {
                    sshagent(credentials: ['lab2-ssh-key']) {
                        sh '''
                            set -e
                            ansible aws_lab2 \
                              -i inventory.ini \
                              -b -m command \
                              -a "docker ps" \
                              -e 'ansible_ssh_private_key_file=' \
                              -e 'ansible_ssh_common_args=-o IdentitiesOnly=no'
                        '''
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'CI/CD Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed. Check Console Output.'
        }
    }
}
