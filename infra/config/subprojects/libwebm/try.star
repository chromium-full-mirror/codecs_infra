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

This configuration defines libwebm try builders.

After modifying this file execute ('lucicfg generate main.star') to regenerate
the configs.
"""

load("//lib/common.star", "LIBWEBM_REPO_URL", "REPO_REFS")
load("//lib/try_helper.star", "try_helper")

# Libwebm compile configuration matrix.
_LIBWEBM_COMPILE_BUILD_TYPES = ["static", "static-debug"]
_LIBWEBM_COMPILE_TARGETS = {
    "x86_64-linux-gnu": "native",
    "x86_64-linux-clang": "native-clang",
    "x86_64-linux-gnu-make": "native-Makefile.unix",
    "i686-w64-mingw32": "i686-w64-mingw32",
    "x86_64-w64-mingw32": "x86_64-w64-mingw32",
}

libwebm_try_builder = try_helper.setup_builder(
    prefix = "libwebm",
    repo = LIBWEBM_REPO_URL,
    refs = [REPO_REFS],
)

def _libwebm_compile_builder(*, name, **kwargs):
    builders = []
    for config in _LIBWEBM_COMPILE_BUILD_TYPES:
        for host, target in _LIBWEBM_COMPILE_TARGETS.items():
            build_type = "" if config == "static" else "-debug"
            builder_name = "%s-%s%s" % (name, host, build_type)
            properties = {
                "script_name": "compile.sh",
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

libwebm_try_builder(
    name = "compile",
    builder_creator = _libwebm_compile_builder,
    recipe = "run_infra_script",
)
libwebm_try_builder(name = "patch-check", builder_creator = try_helper.patch_check_builder)
