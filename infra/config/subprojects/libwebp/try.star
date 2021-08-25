# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""Builders supporting recipes ecosystem.

This configuration defines libwebp try builders.

After modifying this file execute ('lucicfg generate main.star') to regenerate
the configs.
"""

load("//lib/common.star", "LIBWEBP_REPO_URL", "REPO_REFS")
load("//lib/try_helper.star", "try_helper")

# Libwebp compile configuration matrix.
_LIBWEBP_COMPILE_BUILD_TYPES = ["shared", "static", "static-debug"]
_LIBWEBP_COMPILE_TARGETS = [
    "i686-linux-gnu",
    "i686-linux-asan",
    "i686-linux-clang",
    "x86_64-linux-gnu",
    "x86_64-linux-clang",
    "x86_64-linux-msan",
    "i686-w64-mingw32",
    "x86_64-w64-mingw32",
    "aarch64-linux-gnu",
    "aarch64-linux-clang",
    "arm-linux-gnueabi",
    "arm-neon-linux-gnueabi",
    "mips2el-linux-gnu",
    "mips32el-linux-gnu",
    "mips32r2el-linux-gnu",
    "mips32dspr2el-linux-gnu",
    "mips32r5el-linux-gnu",
    "mips32eb-linux-gnu",
    "mips64r2el-linux-gnu",
    "mips64r6el-linux-gnu",
    "native",
    "force-aligned-32",
    "force-aligned-64",
    "visibility-default-gnu",
    "visibility-hidden-gnu",
    "visibility-hidden-clang",
    "disable-sse4.1",
    "cmake",
    "cmake-aarch64",
    "cmake-arm",
    "cmake-clang",
    "gradle",
    "wasm",
    "disable-near-lossless",
    "disable-stats",
    "reduce-size",
    "reduce-size-disable-stats",
    "reduce-csp",
]

def _libwebp_compile_builder(
        *,
        name,
        script_name,
        build_types = [],
        compile_targets = [],
        **kwargs):
    """Defines Libwebp compiler builds

    Args:
      name: name of builder
      script_name: compilation script
      build_types: compilation script build type list
      compile_targets: host platform list
      **kwargs: other keywords args
    """
    builders = []
    for config in build_types:
        for target in compile_targets:
            if "debug" in config:
                build_type = "-debug"
            elif "shared" in config:
                build_type = "-shared"
            else:
                build_type = ""

            builder_name = "%s-%s%s" % (name, target, build_type)
            properties = {
                "script_name": script_name,
                "script_arg": [config, target],
            }

            builders.append(
                try_helper.create_builder(
                    name = builder_name,
                    os = "linux",
                    properties = properties,
                    **kwargs
                ),
            )
    return builders

libwebp_try_builder = try_helper.setup_builder(
    prefix = "libwebp",
    repo = LIBWEBP_REPO_URL,
    refs = [REPO_REFS],
)

# Style-check and patch check builder for libwebp.
libwebp_try_builder(
    name = "patch-check",
    builder_creator = try_helper.patch_check_builder,
)

# Defines libwebp builds for unix-based and mingw cross-compiled platforms.
# e.g.:
# - libwebp-compile-i686-linux-gnu
# - libwebp-compile-aarch64-linux-clang-debug
# For more details, please refer to infra/config/generated/commit-queue.cfg.
libwebp_try_builder(
    name = "compile",
    builder_creator = _libwebp_compile_builder,
    script_name = "compile.sh",
    build_types = _LIBWEBP_COMPILE_BUILD_TYPES,
    compile_targets = _LIBWEBP_COMPILE_TARGETS,
    recipe = "run_infra_script",
)
