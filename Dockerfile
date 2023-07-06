FROM golang:1.20-alpine as ke-builder
ARG image_version
ARG client
ENV RELEASE=$image_version
ENV CLIENT=$client
ENV GO111MODULE=
ENV CGO_ENABLED=1
# Install required python/pip
ENV PYTHONUNBUFFERED=1
RUN apk add --update --no-cache python3 gcc make git libc-dev binutils-gold cmake pkgconfig && ln -sf python3 /usr/bin/python
RUN python3 -m ensurepip
RUN pip3 install --no-cache --upgrade pip setuptools
WORKDIR /work
ADD . .
# install libgit2
RUN rm -rf git2go && make libgit2
# build kubescape server
WORKDIR /work/httphandler
RUN python build.py
RUN ls -ltr build/
# build kubescape cmd
WORKDIR /work
RUN python build.py
RUN /work/build/kubescape-ubuntu-latest download artifacts -o /work/artifacts


FROM golang:1.17 AS ka-builder
# no need to include cgo bindings
ENV CGO_ENABLED=0 GOOS=linux GOARCH=amd64
# add ca certificates and timezone data files
# hadolint ignore=DL3008
RUN apt-get install --yes --no-install-recommends ca-certificates tzdata
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
# add-in our timezone data file
COPY --from=ka-builder /usr/share/zoneinfo /usr/share/zoneinfo

# add-in our ca certificates
COPY --from=ka-builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=ka-builder --chown=app /go/bin/kubeaudit /kubeaudit

# Install linPEAS
RUN git clone https://github.com/carlospolop/PEASS-ng.git /opt/linpeas

# Install kubescape
#RUN curl -LO https://github.com/kubescape/kubescape/releases/latest/download/kubescape && \
#    chmod +x kubescape && \
#    mv kubescape /usr/local/bin/
COPY --from=ke-builder /work/artifacts/ /home/app/.kubescape
RUN chown -R app:app /home/ks/.kubescape
USER app
WORKDIR /home/app
COPY --from=ke-builder /work/httphandler/build/kubescape-ubuntu-latest /usr/bin/ksserver
COPY --from=ke-builder /work/build/kubescape-ubuntu-latest /usr/bin/kubescape

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
