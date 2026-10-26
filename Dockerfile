# Dockerfile minimal pour TD1 — DataOps
# ------------------------------------------------------------------
# CORRECTION: On installe explicitement 'gawk' car l'image Ubuntu de
# base n'inclut PAS 'awk' par défaut. Dans le TD, certains utilisaient
# 'awk' directement -> cela échouait sur une image minimale.
# ------------------------------------------------------------------
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    gawk \
    curl \
    ca-certificates \
    locales \
    tzdata git jq file\
    # CORRECTION (optionnel): utilitaire pour normaliser les fins de ligne
    dos2unix \
  && rm -rf /var/lib/apt/lists/*

# Locales de confort (UTF-8)
RUN locale-gen fr_FR.UTF-8 en_US.UTF-8 || true
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

# Dossier de travail par défaut
WORKDIR /work

# CORRECTION: On NE copie pas les fichiers par défaut, on compte sur le
# montage (-v) côté hôte pour garder un cycle d'édition rapide.
# COPY . /work

# Commande par défaut: shell interactif
CMD ["bash"]
