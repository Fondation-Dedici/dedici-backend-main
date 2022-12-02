# ================================
# Build image
# ================================
FROM swift:5.7.1 as build

ARG SSH_PRIVATE_KEY
ARG GIT_URL
ARG GIT_TARGET

RUN mkdir -p ~/.ssh && \
    chmod 755 ~/.ssh && \
    cd ~/.ssh && \
    touch id_rsa && \
    chmod 600 id_rsa && \
    git config --global advice.detachedHead false && \
    echo "Host *\n StrictHostKeyChecking no\n" > config && \
    echo "${SSH_PRIVATE_KEY}" > id_rsa && \
    git clone "${GIT_URL}" /build && \
    cd /build && \
    git checkout "${GIT_TARGET}" && git log -q1 && \
    rm -rf .git* && \
    swift build --enable-test-discovery -c release

# ================================
# Run image
# ================================
FROM swift:5.7.1-slim

# Create a vapor user and group with /app as its home directory
RUN useradd --user-group --create-home --system --skel /dev/null --home-dir /app vapor

# Switch to the new home directory
WORKDIR /app

# Copy build artifacts
COPY --from=build --chown=vapor:vapor /build/.build/release /app

# Ensure all further commands run as the vapor user
USER vapor:vapor

# Start the Vapor service when the image is run 
ENTRYPOINT ["./Run"]
CMD ["serve"]
