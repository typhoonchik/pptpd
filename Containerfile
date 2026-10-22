FROM debian:trixie-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        nftables \
	    procps \
        pptpd && \
    rm -rf /var/lib/apt/lists/*

COPY ./etc/pptpd.conf /etc/pptpd.conf
COPY ./etc/ppp/options /etc/ppp/options
COPY ./etc/ppp/pptpd-options /etc/ppp/pptpd-options
COPY ./entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod 0700 /usr/local/bin/entrypoint.sh

EXPOSE 1723/tcp

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["pptpd", "--fg"]
