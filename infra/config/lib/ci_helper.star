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

The `ci_helper` configuration defined in this module enables defining a CI
builder. All of its functions can be accessed through the `ci_helper` struct.

The `setup_builder` sets up default configurations needed for the ci builder to
operate.
After modifying this file execute ('lucicfg generate main.star') to regenerate
the configs.
"""

load(
    "//lib/common.star",
    "CI_BUILDER_ACCOUNT",
    "CODECS_CIPD_DEPS_MAPPING",
    "RECIPE_BUNDLE",
    "RECIPE_VERSION",
)

def _create_ci_builder(
        *,
        prefix,
        name,
        recipe,
        dimensions,
        properties = {},
        category,
        triggered_by,
        execution_timeout = 45 * time.minute,
        **kwargs):
    """Defines a post-submit builder.

    Args:
      prefix: prefix name for all builders created from the same setup
      name: builder name
      recipe: recipe name
      dimensions: dict with os, cpu, and other vm settings
      category: console view category
      properties: recipe's input properties
      triggered_by: agent triggering the build (i.e. git poller, another
          builder)
      execution_timeout: timeout for the builder
      **kwargs: injected keywords
    """

    builder_name = "%s-%s" % (prefix, name)
    luci.builder(
        name = builder_name,
        bucket = "ci",
        executable = luci.recipe(
            name = recipe,
            cipd_package = RECIPE_BUNDLE,
            cipd_version = RECIPE_VERSION,
        ),
        properties = properties,
        dimensions = dimensions,
        service_account = CI_BUILDER_ACCOUNT,
        execution_timeout = execution_timeout,
        triggered_by = triggered_by,
    )

    # Add it to the console as well.
    luci.console_view_entry(
        builder = "ci/" +
                  builder_name,  # disambiguate by prefixing the bucket name.
        console_view = "CI Console",
        category = category,
    )

def _setup_builder(
        prefix,
        repo,
        refs,
        *,
        category = "Linux|18",
        cipd_packages = [],
        cpu_arch = "x86-64",
        os = "Ubuntu"):
    """Defines defaults for ci builder creation.

    Args:
      prefix: prefix name for all builders created from the same setup
      repo: repo which git poller is watching
      refs: refs which git poller is watching
      category: console view category
      cipd_packages: list of packages for cipd ensure -ensure-file
      cpu_arch: cpu architecture (e.g. x86-64)
      os: operating system this builder works with
    """
    git_poller = prefix + "-poller"

    # The gitiles poller: a source of commits that trigger CI builders.
    luci.gitiles_poller(
        name = git_poller,
        bucket = "ci",
        repo = repo,
        refs = refs,
    )

    def build(
            *,
            name,
            builder_creator = _create_ci_builder,
            schedule = None,
            properties = {},
            **kwargs):
        """Enclosed build function.
        Args:
            name: name suffix for builders created
            builder_creator: ci builder callback
            schedule: crontab expression (UTC), when the builder should be
                triggered
            properties
            **kwargs: args injected to builder_creator
        """
        dimensions = {
            "os": os,
            "cpu": cpu_arch,
            "pool": "luci.open-codecs.ci",
        }

        if cipd_packages:
            cipd_pkg_defs = [CODECS_CIPD_DEPS_MAPPING[k] for k in cipd_packages]
            properties["$codecs/prerequisites"] = {
                "cipd_package": cipd_pkg_defs,
            }
        else:
            properties["$codecs/prerequisites"] = {
                "cipd_package": [],
            }

        # https://chromium.googlesource.com/infra/luci/luci-go/+/refs/heads/main/lucicfg/doc/README.md#schedules_doc
        if schedule:
            scheduled_poller = "%s-%s-poller" % (prefix, name)
            luci.gitiles_poller(
                name = scheduled_poller,
                bucket = "ci",
                repo = repo,
                refs = refs,
                schedule = schedule,
            )
            triggered_by = [scheduled_poller]
        else:
            triggered_by = [git_poller]

        builder_creator(
            prefix = prefix,
            name = name,
            dimensions = dimensions,
            category = category,
            properties = properties,
            triggered_by = triggered_by,
            schedule = schedule,
            **kwargs
        )

    return build

ci_helper = struct(
    setup_builder = _setup_builder,
    create_builder = _create_ci_builder,
)
