FROM public.ecr.aws/amazonlinux/amazonlinux:2023-minimal

ARG TARGETARCH
ARG AWS_EMULATOR_VERSION
COPY packages/aws-emulator-${TARGETARCH}.rpm /tmp/aws-emulator.rpm
RUN rpm -i /tmp/aws-emulator.rpm \
    && rm /tmp/aws-emulator.rpm \
    && mkdir -p /home/emulator/.aws/emulator \
    && chown -R 10001:10001 /home/emulator

LABEL org.opencontainers.image.source="https://github.com/ctyano/docker-aws-emulator" \
      org.opencontainers.image.title="AWS Emulator" \
      org.opencontainers.image.version="${AWS_EMULATOR_VERSION}"

USER 10001:10001
ENV HOME=/home/emulator
EXPOSE 9297
ENTRYPOINT ["aws-emulator", "--bind", "0.0.0.0", "--telemetry", "off"]
