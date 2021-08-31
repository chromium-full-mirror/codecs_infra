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

This configuration defines libwebp ci builders.

After modifying this file execute ('lucicfg generate main.star') to regenerate
the configs.
"""

load(
    "//lib/common.star",
    "EMSDK_DIR",
    "LIBWEBP_REPO_URL",
    "REPO_REFS",
)
load("//lib/ci_helper.star", "ci_helper")

libwebp_ci_builder = ci_helper.setup_builder(
    prefix = "libwebp",
    repo = LIBWEBP_REPO_URL,
    refs = [REPO_REFS],
)

# Defines libwebp builds for Emscripten SDK (JS) platforms.
libwebp_ci_builder(
    name = "compile-js",
    recipe = "run_infra_script",
    properties = {
        "script_name": "compile_js.sh",
        "script_arg": [],
        "env": {"EMSDK_DIR": EMSDK_DIR},
    },
    schedule = "0 9 * * *",
)
