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

This configuration bundles recipe scripts under infra/config/recipes into a
package and uploads to CIPD.
After modifying this file execute ('lucicfg generate main.star') to regenerate
the configs.
"""

# Load from common starlark file.
load(
    "//lib/common.star",
    "CI_BUILDER_ACCOUNT",
    "CODECS_INFRA_REPO_URL",
    "REPO_REFS",
)

# Recipe bundler cipd prefix.
_RECIPE_BUNDLER_CIPD_PREFIX = "infra/recipe_bundles"

# The Recipes builder list with all cipd bundler builders, referenced below.
luci.list_view(
    name = "recipes-bundlers",
    title = "Recipe bundling builders",
)

def recipe_bundler(name, repo_specs, triggered_by = None):
    """Creates a builder to bundle recipe scripts into cipd packages.

    Recipe scripts from recipes/ directory are bundled into cipd package
    and upload to
    https://chrome-infra-packages.appspot.com/p/infra/recipe_bundles/chromium.googlesource.com/codecs/infra/+/

    Args:
      name: Builder name. This will be the name of recipe builder that
          builds
      cipd packages for cdm recipes.
      repo_specs: repository where the recipes needs to be fetched to bundle
          into a cipd package.
      triggered_by: gitiles poller which triggers this builder.
    """
    properties = {
        # This property controls the version of the recipe_bundler go tool:
        #   https://chromium.googlesource.com/infra/infra/+/master/go/src/infra/tools/recipe_bundler
        "recipe_bundler_vers": "latest",
        # These control the prefix of the CIPD package names that the tool
        # will create.
        "package_name_prefix": _RECIPE_BUNDLER_CIPD_PREFIX,
        # The CIPD package prefix for internal recipes.
        "package_name_internal_prefix": _RECIPE_BUNDLER_CIPD_PREFIX,
        # Where to grab the recipes to bundle.
        "repo_specs": repo_specs,
    }

    luci.builder(
        name = name,
        bucket = "ci",
        priority = 20,
        description_html =
            "Builder to bundle recipe changes and upload bundled recipe package to CIPD.",
        executable = luci.recipe(
            name = "recipe_bundler",
            cipd_package =
                "infra/recipe_bundles/chromium.googlesource.com/infra/infra",
            cipd_version = "refs/heads/main",
            use_bbagent = True,
        ),
        dimensions = {
            "pool": "luci.open-codecs.ci",
            "os": "Ubuntu",
            "cpu": "x86-64",
        },
        properties = properties,
        service_account = CI_BUILDER_ACCOUNT,
        expiration_timeout = 15 * time.minute,
        execution_timeout = 10 * time.minute,
        triggered_by = triggered_by,
    )
    luci.list_view_entry(
        builder = name,
        list_view = "recipes-bundlers",
    )

def poller(name, repo):
    """Create a poller for with given name on given repository.

    This polls for any commits on repository.

    Args:
      name: name of the gitiles poller.
      repo: Git-on-Borg repostory to poll for.
    """
    return luci.gitiles_poller(
        name = name,
        bucket = "ci",
        repo = repo,
        refs = [REPO_REFS],
    )

# MUST NOT include scheme in prod, otherwise causes mixed content on GWS (due
# to potentially mixing HTTP and HTTPS).
repo_spec = "%(url)s=FETCH_HEAD,%(refs)s" % {
    "url": CODECS_INFRA_REPO_URL.replace("https://", ""),
    "refs": REPO_REFS,
}

# Create recipe-bundler builder to bundle recipe scripts into cipd packages.
recipe_bundler(
    name = "recipe-bundler",
    repo_specs = [
        repo_spec,
    ],
    triggered_by = [
        poller("open-codecs", CODECS_INFRA_REPO_URL),
    ],
)
