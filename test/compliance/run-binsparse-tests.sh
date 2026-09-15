#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2026 Finch Developers
# SPDX-License-Identifier: MIT
#
# Run the Binsparse compliance test suite against Finch.jl.
# Modelled after taco-binsparse-parser/test/compliance/run-binsparse-tests.sh

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/../.." && pwd)"
build_dir="${BINSPARSE_BUILD_DIR:-${repo_root}/build-compliance}"
tests_dir="${BINSPARSE_TESTS_DIR:-${build_dir}/binsparse-tests}"
tests_ref="${BINSPARSE_TESTS_REF:-main}"

# check prerequisites
for command in git pixi julia; do
  if ! command -v "${command}" >/dev/null 2>&1; then
    echo "error: required command '${command}' was not found" >&2
    exit 1
  fi
done

# clone / update binsparse-tests
mkdir -p "${build_dir}"

if [[ -d "${tests_dir}/.git" ]]; then
  git -C "${tests_dir}" fetch --depth 1 origin "${tests_ref}"
  git -C "${tests_dir}" checkout --detach FETCH_HEAD
elif [[ -e "${tests_dir}" ]]; then
  echo "error: ${tests_dir} exists but is not a Git checkout" >&2
  exit 1
else
  git clone --depth 1 https://github.com/Binsparse/binsparse-tests.git \
    "${tests_dir}"
  if [[ "${tests_ref}" != "main" ]]; then
    git -C "${tests_dir}" fetch --depth 1 origin "${tests_ref}"
    git -C "${tests_dir}" checkout --detach FETCH_HEAD
  fi
fi

# install binsparse-tests Python environment
(
  cd "${tests_dir}"
  pixi install -e test-hdf5
)

# instantiate the Julia test project so the CLI works
julia --project="${repo_root}/test" -e '
  using Pkg
  Pkg.develop(PackageSpec(; path=ARGS[1]))
  Pkg.instantiate()
' "${repo_root}"

# point the harness at the Finch CLI wrappers
export BINSPARSE_TO_NPY="${script_dir}/binsparse_to_npy"
export BINSPARSE_TO_BINSPARSE="${script_dir}/binsparse_to_binsparse"

if [[ -z "${NPY_TO_BINSPARSE:-}" ]]; then
  export NPY_TO_BINSPARSE="${script_dir}/npy_to_binsparse"
fi

# run pytest
(
  cd "${tests_dir}"
  pixi run -e test-hdf5 pytest -m hdf5 \
    --skips-file "${script_dir}/skips.txt" \
    binsparse_tests/ "$@"
)
