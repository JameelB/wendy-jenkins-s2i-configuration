#!/bin/sh -xe
TEMPLATES_DIR="/home/jbriones/go/src/github.com/feedhenry/wendy-jenkins-s2i-configuration/templates"
DOCKER_USERNAME=""
DOCKER_PASSWORD=""
DOCKER_EMAIL=""

oc new-project $PROJECT_NAME

oc secrets new-dockercfg dockerhub --docker-server=docker.io --docker-username=$DOCKER_USERNAME --docker-password=$DOCKER_PASSWORD --docker-email=$DOCKER_EMAIL

for AGENT in java-ubuntu jenkins-tools nodejs-ubuntu nodejs6-ubuntu ruby ruby-fhcap ansible go-centos7 python2-centos7 nodejs6-centos7 svcat circleci
do
    AGENT_LABELS="$AGENT ${AGENT/-/ } openshift"

    if [ "$AGENT" = "nodejs-ubuntu" ] ; then
        AGENT_LABELS="ubuntu nodejs4-ubuntu"
    fi

    if [ "$AGENT" = "nodejs6-ubuntu" ] ; then
        AGENT_LABELS="ubuntu nodejs6-ubuntu"
    fi

    oc new-app -p AGENT_LABEL="$AGENT_LABELS" -p IMAGE_NAME=jenkins-agent-$AGENT -f  $TEMPLATES_DIR/agent-image-template.yml
done

oc new-app -f  $TEMPLATES_DIR/jenkins-image-template.yaml

# Adding create project access to system:serviceaccount:$PROJECT_NAME:jenkins
oc adm policy add-cluster-role-to-user self-provisioner system:serviceaccount:$PROJECT_NAME:jenkins
oc new-app -p MEMORY_LIMIT=2Gi -p NAMESPACE=$PROJECT_NAME -p JENKINS_IMAGE_STREAM_TAG=jenkins:latest -f  $TEMPLATES_DIR/jenkins-template.yml
oc import-image jenkins:latest -n $PROJECT_NAME
