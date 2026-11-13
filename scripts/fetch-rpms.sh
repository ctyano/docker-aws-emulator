#!/usr/bin/env bash
set -euo pipefail

root_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
package_dir="${root_dir}/packages"
mkdir -p "$package_dir"

url_for() {
    printf 'https://downloads.aws.com/aws-emulator/packages/aws-emulator/LTS/latest/aws-emulator-%s.rpm' "$1"
}

header_value() {
    awk -F ': ' -v name="$1" 'tolower($1) == name {gsub(/\r/, "", $2); value=$2} END {print value}'
}

fetch_headers() {
    curl --fail --silent --show-error --location --head --retry 3 --retry-all-errors "$(url_for "$1")"
}

x86_headers=$(fetch_headers x86_64)
arm_headers=$(fetch_headers aarch64)
version=$(printf '%s\n' "$x86_headers" | header_value x-amz-meta-package-version)
arm_version=$(printf '%s\n' "$arm_headers" | header_value x-amz-meta-package-version)
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || [[ "$version" != "$arm_version" ]]; then
    echo "AWS Emulator package versions are missing or differ between architectures" >&2
    exit 1
fi

if [[ "${1:-}" == --resolve ]]; then
    printf 'VERSION=%s\n' "$version" > "${package_dir}/release.env"
    printf '%s\n' "$version"
    exit 0
fi
if [[ $# -gt 0 ]]; then
    echo "usage: $0 [--resolve]" >&2
    exit 2
fi

for entry in 'amd64 x86_64' 'arm64 aarch64'; do
    read -r target_arch rpm_arch <<< "$entry"
    package="${package_dir}/aws-emulator-${target_arch}.rpm"
    original_headers=$([[ "$target_arch" == amd64 ]] && printf '%s' "$x86_headers" || printf '%s' "$arm_headers")
    original_etag=$(printf '%s\n' "$original_headers" | header_value etag)
    curl --fail --silent --show-error --location --retry 3 --retry-all-errors \
        --output "${package}.tmp" "$(url_for "$rpm_arch")"
    current_headers=$(fetch_headers "$rpm_arch")
    current_version=$(printf '%s\n' "$current_headers" | header_value x-amz-meta-package-version)
    current_etag=$(printf '%s\n' "$current_headers" | header_value etag)
    if [[ "$current_version" != "$version" || "$current_etag" != "$original_etag" ]]; then
        echo "AWS Emulator ${rpm_arch} package changed while downloading; retry the workflow" >&2
        exit 1
    fi
    mv "${package}.tmp" "$package"
done

printf 'VERSION=%s\n' "$version" > "${package_dir}/release.env"
for target_arch in amd64 arm64; do
    package="${package_dir}/aws-emulator-${target_arch}.rpm"
    printf '%s  %s\n' "$(openssl dgst -sha256 -r "$package" | awk '{print $1}')" "$(basename "$package")"
done
