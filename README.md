# AWS Emulator container image

This repository packages the [AWS Emulator](https://github.com/aws/aws-emulator) RPM in the AWS supplied Amazon Linux image. AWS [does not publish a prebuilt container image](https://docs.aws.amazon.com/emulator/latest/userguide/getting-started-docker.html); the Dockerfile follows its documented packaging approach. It does not build or modify the emulator source.

The workflow checks the AWS `LTS/latest` RPM metadata every Saturday and on manual dispatch. When a new package version is available, it downloads both architecture packages, confirms that their versions match, and publishes `ghcr.io/ctyano/docker-aws-emulator:<version>` and `:latest` for `linux/amd64` and `linux/arm64`. Pull requests build the image without publishing it. A push to `main` also rebuilds the image, so Dockerfile changes can be released without waiting for a new RPM.

For a local build:

```sh
./scripts/fetch-rpms.sh
docker build -t aws-emulator:latest .
```

The script prints SHA-256 digests of both downloaded RPMs. The RPM files are ignored by Git and copied into the build context, so the image build uses the exact packages downloaded and checked by the workflow. The emulator starts on HTTPS port 9297 with telemetry disabled. Its generated credentials and CA are stored under `$HOME/.aws/emulator/9297` inside the container. This image is for local development and tests, following the [upstream security guidance](https://docs.aws.amazon.com/emulator/latest/userguide/security.html).
