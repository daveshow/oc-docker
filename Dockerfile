FROM node:alpine

RUN apk update && apk upgrade --no-cache && \
    apk add --no-cache python3 py3-pip curl bash tar && \
    pip3 install --break-system-packages uv && \
    curl -fsSL https://opencode.ai/install | bash && \
    # Verify installation
    ls -la $HOME/.opencode/bin/ && \
    echo 'export PATH="$HOME/.opencode/bin:$PATH"' >> ~/.bashrc

RUN mkdir -p /config /data/sessions /data/snapshots /data/log /projects /mcp

COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Copy config - support both .json and .jsonc
COPY config/opencode.json* /config/
RUN if [ -f /config/opencode.jsonc ]; then \
    mv /config/opencode.jsonc /config/opencode.json; \
    fi

EXPOSE 4096

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["web"]
