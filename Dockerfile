FROM bitnami/kubectl
COPY ha-label-manager.sh /script/ha-label-manager.sh
USER root
RUN chmod 0755 /script/ha-label-manager.sh
USER 1001
ENTRYPOINT /script/ha-label-manager.sh