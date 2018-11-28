FROM asciidoctor/docker-asciidoctor
LABEL MAINTAINERS="OpenStandia"

# Timezone
RUN ln -fs /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

# Adding fonts
RUN apk add --no-cache ttf-dejavu

# Adding japanese fonts
WORKDIR /root
RUN gem install asciidoctor-pdf-cjk-kai_gen_gothic --no-ri --no-rdoc && \
    asciidoctor-pdf-cjk-kai_gen_gothic-install && \
    curl -L "http://osdn.jp/frs/redir.php?m=jaist&f=%2Fvlgothic%2F62375%2FVLGothic-20141206.zip" > VLGothic.zip && \
    unzip VLGothic.zip && \
    mkdir -p /root/.fonts && \
    cp VLGothic/VL-Gothic-Regular.ttf /root/.fonts && \
    rm -rf /root/VLGothic*

# Adding asciidoctor-stylesheet-factory
ENV COMPASS_VERSION 0.12.7
ENV ZURB_FOUNDATION_VERSION 4.3.2
RUN gem install --version ${COMPASS_VERSION} compass --no-ri --no-rdoc && \
    gem install --version ${ZURB_FOUNDATION_VERSION} zurb-foundation --no-ri --no-rdoc && \
    curl -LO https://github.com/asciidoctor/asciidoctor-stylesheet-factory/archive/master.zip && \
    unzip master.zip && \
    cd asciidoctor-stylesheet-factory-master && \
    compass compile && \
    mv stylesheets / && \
    mv images / && \
    cd .. && \
    rm -rf master.zip asciidoctor-stylesheet-factory-master
   
# Adding pandoc for docx conversion
RUN curl -L -o pandoc.tar.gz https://github.com/jgm/pandoc/releases/download/2.3.1/pandoc-2.3.1-linux.tar.gz && \
    tar xzf pandoc.tar.gz && \
    mv pandoc*/bin/pandoc* /usr/bin/ && \
    rm -rf pandoc.tar.gz pandoc*

# Adding asciidoctor-diagram-office
RUN apk --no-cache add \
    libreoffice
ARG UNO_URL=https://raw.githubusercontent.com/dagwieers/unoconv/master/unoconv
RUN curl -Ls $UNO_URL -o /usr/local/bin/unoconv && \
    chmod +x /usr/local/bin/unoconv && \
    sed -i -e "s|#!/usr/bin/env python|#!/usr/bin/env python3|" /usr/local/bin/unoconv
RUN apk --no-cache add imagemagick inkscape
RUN gem install --no-document asciidoctor-diagram-office --version 0.1.2

# Adding html2pdf script with puppeteer
WORKDIR /opt/html2pdf
COPY html2pdf.js /opt/html2pdf/
COPY html2pdf /usr/local/bin/
RUN apk add nodejs nodejs-npm libuv zip --no-cache
RUN apk update && apk upgrade && \
    echo @edge http://nl.alpinelinux.org/alpine/edge/community >> /etc/apk/repositories && \
    echo @edge http://nl.alpinelinux.org/alpine/edge/main >> /etc/apk/repositories && \
    apk add --no-cache \
      chromium@edge \
      nss@edge \
      freetype@edge \
      harfbuzz@edge
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD true
RUN npm i puppeteer express

# Adding aws-cli
RUN apk add --no-cache --virtual .pythonmakedepends \
    build-base \
    python2-dev \
    py2-pip \
  && pip install --upgrade pip \
  && pip install --no-cache-dir \
    awscli \
  && apk del -r --no-cache .pythonmakedepends

# Adding mermaid.cli
RUN mkdir -p /var/lib/mermaid \
  && cd /var/lib/mermaid \
  && npm i mermaid.cli \
  && sed -i -e "s|let puppeteerConfig = {};|let puppeteerConfig = { args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-gpu'], executablePath: '/usr/bin/chromium-browser' }|" ./node_modules/mermaid.cli/index.bundle.js
ENV PATH $PATH:/var/lib/mermaid/node_modules/.bin

WORKDIR /documents

CMD ["/bin/bash"]
