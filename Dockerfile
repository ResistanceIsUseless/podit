ROM golang:1.17 AS builder

# no need to include cgo bindings
ENV CGO_ENABLED=0 GOOS=linux GOARCH=amd64

# add ca certificates and timezone data files
# hadolint ignore=DL3008
RUN apt-get install --yes --no-install-recommends ca-certificates tzdata

# add unprivileged user
RUN adduser --shell /bin/true --uid 1000 --disabled-login --no-create-home --gecos '' app \
  && sed -i -r "/^(app|root)/!d" /etc/group /etc/passwd \
  && sed -i -r 's#^(.*):[^:]*$#\1:/sbin/nologin#' /etc/passwd

# this is where we build our app
WORKDIR /go/src/app/

# download and cache our dependencies
VOLUME /go/pkg/mod
COPY go.mod go.sum ./
RUN go mod download

# compile kubeaudit
COPY . ./
RUN go build -a -ldflags '-w -s -extldflags "-static"' -o /go/bin/kubeaudit ./cmd/ \
  && chmod +x /go/bin/kubeaudit

#
# ---
#

# start with empty image
FROM scratch

# add-in our timezone data file
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo

# add-in our unprivileged user
COPY --from=builder /etc/passwd /etc/group /etc/shadow /etc/

# add-in our ca certificates
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# add-in our application

# Base image
FROM --platform=linux/x86_64 alpine:latest

# Install required packages
RUN apk add --no-cache \
    bash \
    curl \
    git \
    libxslt \
    nmap \
    nmap-scripts \
    wget \
    python3 \
    py3-pip

RUN nmap --script-updatedb

#add user app
RUN addgroup -S app && adduser -S app -G app && \
    mkdir -p /home/app && \
    chown -R app:app /home/app

# Install docker-bench-security
RUN git clone https://github.com/docker/docker-bench-security.git /opt/docker-bench-security

# Install kubeaudit
COPY --from=builder --chown=app /go/bin/kubeaudit /kubeaudit

# Install linPEAS
RUN git clone https://github.com/carlospolop/PEASS-ng.git /opt/linpeas

# Install kubescape
RUN curl -LO https://github.com/kubescape/kubescape/releases/latest/download/kubescape && \
    chmod +x kubescape && \
    mv kubescape /usr/local/bin/

# Install nuclei
RUN wget https://github.com/projectdiscovery/nuclei/releases/download/v2.9.7/nuclei_2.9.7_linux_amd64.zip \
   && unzip nuclei_2.9.7_linux_amd64.zip \
   && mv nuclei /usr/local/bin/ \
   && rm nuclei_2.9.7_linux_amd64.zip

RUN git clone https://github.com/ResistanceIsUseless/nmap-parse-output /usr/local/bin/nmap-parse-output

USER app
WORKDIR /home/app
RUN nuclei -ut && nuclei -hc

# Copy entrypoint script
COPY entrypoint.py /home/app/entrypoint.py
COPY requirements.txt /home/app/requirements.txt

RUN python3 -m pip install --upgrade pip \
    && pip3 install -r requirements.txt

EXPOSE 8080

ENTRYPOINT ["python","entrypoint.py"]
