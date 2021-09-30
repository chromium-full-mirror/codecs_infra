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

This configuration runs presubmit checks for all files under codecs/infra.
After modifying this file execute ('lucicfg generate main.star') to regenerate
the configs.
"""

load("//lib//common.star", "CODECS_INFRA_REPO_URL", "REPO_REFS")
load("//lib/try_helper.star", "try_helper")

codecs_infra_try_builder = try_helper.setup_builder(
    prefix = "codecs-infra",
    repo = CODECS_INFRA_REPO_URL,
    refs = [REPO_REFS],
)

def _codecs_infra_patch_check(*, name, dimensions, cq_group, **kwargs):
    luci.builder(
        name = name,
        bucket = "try",
        executable = luci.recipe(
            name = "presubmit",
            cipd_package =
                "infra/recipe_bundles/chromium.googlesource.com/chromium/tools/build",
            cipd_version = "refs/heads/main",
        ),
        properties = {
            "$depot_tools/presubmit": {
                "runhooks": False,
                "timeout_s": 480,
            },
        },
        service_account =
            "open-codecs-try-builder@chops-service-accounts.iam.gserviceaccount.com",
        dimensions = dimensions,
        execution_timeout = 10 * time.minute,
    )

    # Add to the CQ.
    luci.cq_tryjob_verifier(
        builder = "try/" + name,
        cq_group = cq_group,
    )

    # And also to the pre-submit builders list.
    luci.list_view_entry(
        builder = "try/" + name,
        list_view = "Try Builders",
    )

# Create presubmit try builder for codec/infra star files and recipes.
codecs_infra_try_builder(
    name = "patch-check",
    builder_creator = _codecs_infra_patch_check,
)

# Create recipe tests try_builder.
codecs_infra_try_builder(
    name = "recipe-tests",
    recipe = "try_builder",
)
