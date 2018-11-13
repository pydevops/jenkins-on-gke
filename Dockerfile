# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
FROM jenkins/jnlp-slave:3.27-1

# TODO update before release
LABEL \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.docker.dockerfile="/Dockerfile" \
    org.label-schema.license="Apache License 2.0" \
    org.label-schema.name="Jenkins JNLP Agent Docker image" \
    org.label-schema.url="https://hub.docker.com/r/jenkins/jnlp-slave/" \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-type="Git" \
    org.label-schema.vcs-url="https://github.com/jenkinsci/docker-jnlp-slave"

ENV TERRAFORM_VERSION 0.11.10

USER root
# pipefail added for https://github.com/hadolint/hadolint/wiki/DL4006
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# hadolint ignore=DL3008
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates=20161130+nmu1+deb9u1 curl=7.52.1-5+deb9u8 build-essential=12.3  \
    unzip=6.0-21 git=1:2.11.0-3+deb9u4 jq=1.5+dfsg-1.3 && \
    # install terraform
    curl -s -o /terraform.zip "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" && \
    unzip /terraform.zip -d /bin && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

USER jenkins
ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH
ENV USER jenkins