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
RUN wget https://github.com/Shopify/kubeaudit/releases/download/v0.22.0/kubeaudit_0.22.0_linux_amd64.tar.gz \
    && tar xvf kubeaudit_0.22.0_linux_amd64.tar.gz \
    && mv kubeaudit /usr/local/bin \
    && rm kubeaudit_0.22.0_linux_amd64.tar.gz

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
