FROM python:3.11-slim-bookworm AS builder

# Build dummy packages to skip installing them and their dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends equivs \
    && equivs-control libgl1-mesa-dri \
    && printf 'Section: misc\nPriority: optional\nStandards-Version: 3.9.2\nPackage: libgl1-mesa-dri\nVersion: 99.0.0\nDescription: Dummy package for libgl1-mesa-dri\n' >> libgl1-mesa-dri \
    && equivs-build libgl1-mesa-dri \
    && mv libgl1-mesa-dri_*.deb /libgl1-mesa-dri.deb \
    && equivs-control adwaita-icon-theme \
    && printf 'Section: misc\nPriority: optional\nStandards-Version: 3.9.2\nPackage: adwaita-icon-theme\nVersion: 99.0.0\nDescription: Dummy package for adwaita-icon-theme\n' >> adwaita-icon-theme \
    && equivs-build adwaita-icon-theme \
    && mv adwaita-icon-theme_*.deb /adwaita-icon-theme.deb

FROM python:3.11-slim-bookworm

# Copy dummy packages
COPY --from=builder /*.deb /

# Install dependencies and create flaresolverr user
WORKDIR /app
RUN dpkg -i /libgl1-mesa-dri.deb \
    && dpkg -i /adwaita-icon-theme.deb \
    # Install dependencies
    && apt-get update \
    && apt-get install -y --no-install-recommends chromium chromium-common chromium-driver xvfb dumb-init \
        procps curl vim xauth \
    # Remove temporary files and hardware decoding libraries
    && rm -rf /var/lib/apt/lists/* \
    && rm -f /usr/lib/x86_64-linux-gnu/libmfxhw* \
    && rm -f /usr/lib/x86_64-linux-gnu/mfx/* \
    # Create flaresolverr user
    && useradd --home-dir /app --shell /bin/sh flaresolverr \
    && mv /usr/bin/chromedriver chromedriver \
    && chown -R flaresolverr:flaresolverr . \
    # Create config dir
    && mkdir /config \
    && chown flaresolverr:flaresolverr /config

VOLUME /config

# Install Python dependencies
COPY requirements.txt .
RUN pip install -r requirements.txt \
    # Remove temporary files
    && rm -rf /root/.cache

# Copy application files and entrypoint
COPY entrypoint.sh /app/entrypoint.sh
COPY src .
COPY package.json ../

# Ensure permissions for arbitrary non-root UID (Heroku)
RUN chmod +x /app/entrypoint.sh \
    && chmod -R a+rwX /app /config

ENV HOME=/tmp
ENV DISABLE_MEDIA=true
ENV MAX_TIMEOUT_MS=25000

USER flaresolverr

RUN mkdir -p "/app/.config/chromium/Crash Reports/pending"

EXPOSE 8191
EXPOSE 8192

ENTRYPOINT ["/app/entrypoint.sh"]
