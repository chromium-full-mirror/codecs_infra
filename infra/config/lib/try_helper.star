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

The `try_helper` configuration defined in this module enables defining a Try
builder. All of its functions can be accessed through the `try_helper` struct.

The `setup_builder` sets up default configurations needed for the try builder to
operate.
After modifying this file execute ('lucicfg generate main.star') to regenerate
the configs.
"""

load("//lib/common.star", "RECIPE_BUNDLE", "RECIPE_VERSION", "TRY_BUILDER_ACCOUNT")

def _patch_check_builder(
        *,
        prefix,
        name,
        cq_group,
        dimensions,
        execution_timeout = 10 * time.minute,
        **kwargs):
    """Define Patch Check builder

    Args:
      prefix: prefix name for all builders created from the same setup
      name: builder name
      cq_group: cq_group which the builder will be verified with
      dimensions: dict with os, cpu architecture, and other vm settings
      execution_timeout: timeout for the builder
      **kwargs: injected keywords
    """

    builder_name = "%s-%s" % (prefix, name)
    luci.builder(
        name = builder_name,
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
        service_account = TRY_BUILDER_ACCOUNT,
        dimensions = dimensions,
        execution_timeout = execution_timeout,
    )

    # Add to the CQ.
    luci.cq_tryjob_verifier(
        builder = "try/" + builder_name,
        cq_group = cq_group,
    )

    # And also to the pre-submit builders list.
    luci.list_view_entry(
        builder = "try/" + builder_name,
        list_view = "Try Builders",
    )

def _create_try_builder(
        *,
        prefix,
        name,
        recipe,
        cq_group,
        dimensions,
        properties = {},
        execution_timeout = 45 * time.minute,
        **kwargs):
    """Defines a pre-submit builder.

    Args:
      prefix: prefix name for all builders created from the same setup
      name: builder name
      cq_group: cq_group which the builder will be verified with
      recipe: recipe name
      dimensions: dict with os, cpu, and other vm settings
      properties: recipe's input properties
      execution_timeout: timeout for the builder
      **kwargs: injected keywords
    """
    builder_name = "%s-%s" % (prefix, name)

    luci.builder(
        name = builder_name,
        bucket = "try",
        executable = luci.recipe(
            name = recipe,
            cipd_package = RECIPE_BUNDLE,
            cipd_version = RECIPE_VERSION,
        ),
        dimensions = dimensions,
        properties = properties,
        service_account = TRY_BUILDER_ACCOUNT,
        execution_timeout = execution_timeout,
    )

    # Add to the CQ.
    luci.cq_tryjob_verifier(
        builder = "try/" + builder_name,
        cq_group = cq_group,
    )

    # And also to the pre-submit builders list.
    luci.list_view_entry(
        builder = "try/" + builder_name,
        list_view = "Try Builders",
    )

def _setup_builder(
        prefix,
        repo,
        refs,
        *,
        os = "Ubuntu",
        cpu_arch = "x86-64",
        category = "Linux|18",
        execution_timeout = 45 * time.minute):
    """Defines defaults for try builder creation.

    Args:
      prefix: prefix name for all builders created from the same setup
      repo: repo which cq_group is watching
      refs: refs which cq_group is watching
      os: operating system this builder works with
      cpu_arch: cpu architecture (e.g. x86-64)
      category: console view category
      execution_timeout: timeout for the builder
    """
    cq_group = prefix + "CQ"

    def build(*, name, builder_creator = _create_try_builder, **kwargs):
        dimensions = {
            "os": os,
            "cpu": cpu_arch,
            "pool": "luci.open-codecs.try",
        }

        # Builder callback
        builder_creator(
            prefix = prefix,
            cq_group = cq_group,
            name = name,
            dimensions = dimensions,
            category = category,
            execution_timeout = execution_timeout,
            **kwargs
        )

    # The CQ group with all pre-submit builders, referenced below.
    luci.cq_group(
        name = cq_group,
        watch = cq.refset(repo = repo, refs = refs),
    )

    return build

# Public API exposed.
try_helper = struct(
    setup_builder = _setup_builder,
    create_builder = _create_try_builder,
    patch_check_builder = _patch_check_builder,
)
