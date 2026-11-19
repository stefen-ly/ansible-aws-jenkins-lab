
pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        skipDefaultCheckout(true)
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
                sh '''
                    set -e
                    cd "$LAB_DIR"

                    ansible-playbook \
                      playbook/fileupload-main.yaml \
                      --syntax-check

                    ansible-inventory \
                      -i inventory.ini --graph
                '''
            }
        }

        stage('3. Build & Push Docker Image') {
            steps {
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
                        cd "$LAB_DIR"

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


        stage('4. Deploy to AWS EC2') {
            steps {
                sshagent(credentials: ['lab2-ssh-key']) {
                    sh '''
                        set -e
                        cd "$LAB_DIR"

                        ansible-playbook \
                        -i inventory.jenkins.ini \
                        playbook/fileupload-deploy.yaml \
                        -f 1 \
                        -e "dockerhub_user=$DOCKERHUB_USER"
                    '''
                }
            }
        }


        stage('SSH Connectivity Test') {
            steps {
                sshagent(credentials: ['lab2-ssh-key']) {
                    sh '''
                        set -e
                        cd "$LAB_DIR"

                        ansible aws_lab2 \
                        -i inventory.ini \
                        -f 1 \
                        -m ping \
                        -e 'ansible_ssh_private_key_file=' \
                        -e 'ansible_ssh_common_args=-o IdentitiesOnly=no'
                    '''
                }
            }
        }


        stage('5. Verify Containers') {
            steps {
                sshagent(credentials: ['lab2-ssh-key']) {
                    sh '''
                        set -e
                        cd "$LAB_DIR"

                        ansible aws_lab2 \
                        -i inventory.jenkins.ini \
                        -f 1 \
                        -b -m command \
                        -a "docker ps"
                    '''
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
