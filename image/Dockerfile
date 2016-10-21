# ubuntu:xenial is same base as Aerospike 3.10.0.1, saving disk space
FROM ubuntu:xenial

# The peer-finder script provided by google
ADD https://storage.googleapis.com/kubernetes-release/pets/peer-finder /peer-finder

# Local files
ADD install.sh /
ADD on-start.sh /
ADD aerospike.conf /

# Make scripts runnable
RUN chmod -c 755 /peer-finder && chmod -c 755 /install.sh && chmod -c 755 /on-start.sh

ENTRYPOINT /install.sh
