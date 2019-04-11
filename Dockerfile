FROM tweekmonster/vim-testbed:latest

ENV PACKAGES="bash git python py-pip"

RUN apk --update add $PACKAGES && \
    rm -rf /var/cache/apk/* /tmp/* /var/tmp/*

RUN pip install vim-vint==0.3.15
