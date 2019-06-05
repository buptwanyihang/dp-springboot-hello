pipeline {
    agent any
    environment {
        REGISTRY_CREDS = credentials('jenkins-docker-registry-creds')
        K8S_CONFIG = credentials('jenkins-k8s-config')
        GIT_TAG = sh(returnStdout: true,script: 'git describe --tags `git rev-list --tags --max-count=1`').trim()
        NAMESPACE_SUFFIX = sh(returnStdout: true,script: 'TAG=$(git describe --tags `git rev-list --tags --max-count=1`) && if [ "$TAG" == "${TAG##*-}" ]; then echo "dev"; else echo ${TAG##*-}; fi').trim()
    }
    parameters {
        string(name: 'REGISTRY_HOST', defaultValue: 'registry.cn-beijing.aliyuncs.com', description: '镜像仓库地址')
        string(name: 'DOCKER_IMAGE', defaultValue: 'bigdata_platform/dp-springboot-hello', description: 'docker镜像名')
        string(name: 'APP_NAME', defaultValue: 'dp-springboot-hello', description: 'k8s中标签名')
    }
    stages {
        stage('Print Info') {
            steps {
                sh "echo -e 'APP_NAME: ${params.APP_NAME}\nGIT_TAG: ${GIT_TAG}\nNS_SUFFIX: ${NAMESPACE_SUFFIX}'"
                sh "echo -e 'REGISTRY_HOST: ${params.REGISTRY_HOST}\nDOCKER_IMAGE: ${params.DOCKER_IMAGE}'"
            }
        }
        stage('Maven Build') {
            when { expression { env.GIT_TAG != null } }
            agent {
                docker {
                    image 'maven:3-jdk-8-alpine'
                    args '-v $HOME/.m2:/root/.m2'
                }
            }
            steps {
                sh 'mvn clean package -Dfile.encoding=UTF-8 -DskipTests=true'
                stash includes: 'target/*.jar', name: 'app'
            }
        }
        stage('Docker Build') {
            when { 
                allOf {
                    expression { env.GIT_TAG != null }
                }
            }
            agent any
            steps {
                unstash 'app'
                sh "docker login -u ${REGISTRY_CREDS_USR} -p ${REGISTRY_CREDS_PSW} ${params.REGISTRY_HOST}"
                sh "docker build --build-arg JAR_FILE=`ls target/*.jar |cut -d '/' -f2` -t ${params.REGISTRY_HOST}/${params.DOCKER_IMAGE}:${GIT_TAG} ."
                sh "docker push ${params.REGISTRY_HOST}/${params.DOCKER_IMAGE}:${GIT_TAG}"
                sh "docker rmi ${params.REGISTRY_HOST}/${params.DOCKER_IMAGE}:${GIT_TAG}"
            }
        }
        stage('Deploy') {
            when { 
                allOf {
                    expression { env.GIT_TAG != null }
                }
            }
            agent {
                docker {
                    image 'lwolf/helm-kubectl-docker'
                }
            }
            steps {
                sh "mkdir -p /root/.kube"
                sh "echo ${K8S_CONFIG} | base64 -d > /root/.kube/config"
                sh "sed -e 's#{IMAGE_URL}#${params.REGISTRY_HOST}/${params.DOCKER_IMAGE}#g;s#{IMAGE_TAG}#${GIT_TAG}#g;s#{APP_NAME}#${params.APP_NAME}#g;s#{SPRING_PROFILE}#env-${NAMESPACE_SUFFIX}#g' deployment/k8s-deployment.tpl > deployment/k8s-deployment.yml"
                sh "kubectl apply -f deployment/k8s-deployment.yml --namespace=data-platform-${NAMESPACE_SUFFIX}"
            }
        }
    }
}