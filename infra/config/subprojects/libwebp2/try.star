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

This configuration defines libwebp2 try builders.

After modifying this file execute ('lucicfg generate main.star') to regenerate
the configs.
"""

load("//lib/common.star", "LIBWEBP2_REPO_URL", "REPO_REFS")
load("//lib/try_helper.star", "try_helper")

libwebp2_try_builder = try_helper.setup_builder(
    prefix = "libwebp2",
    repo = LIBWEBP2_REPO_URL,
    refs = [REPO_REFS],
)

libwebp2_try_builder(
    name = "patch-check",
    builder_creator = try_helper.patch_check_builder,
)

libwebp2_try_builder(
    name = "tests-x86_64-linux-gnu",
    recipe = "run_infra_script",
    properties = {
        "script_name": "build_and_test.sh",
        "script_arg": [],
    },
)
