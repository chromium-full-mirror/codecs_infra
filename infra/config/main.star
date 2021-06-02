#!/usr/bin/env lucicfg
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

"""Open Codecs LUCI configuration project.

Defines the LUCI configs. To update the generated files use
'lucicfg generate main.star'.

lucicfg is distributed as a single self-contained binary as part of
depot_tools.
"""

# Load from common starlark file
load(
    "//common.star",
    "RECIPE_BUNDLE",
    "RECIPE_VERSION",
    "REPO_REFS",
    "REPO_URL",
)

# Required depot_tools
lucicfg.check_version("1.18.4", "Please update depot_tools")

# lucicfg configuration
lucicfg.config(
    config_dir = "generated",
    tracked_files = ["*.cfg"],
    fail_on_warnings = True,
    lint_checks = [
        "default",
        "-function-docstring",
        "-function-docstring-args",
        "-function-docstring-return",
        "-module-docstring",
    ],
)

# Definition of what LUCI micro-services to use and global ACLs that apply to
# all buckets.

luci.project(
    name = "open-codecs",
    buildbucket = "cr-buildbucket.appspot.com",
    logdog = "luci-logdog.appspot.com",
    milo = "luci-milo.appspot.com",
    scheduler = "luci-scheduler.appspot.com",
    swarming = "chromium-swarm.appspot.com",
    acls = [
        # This project is publicly readable.
        acl.entry(
            roles = [
                acl.BUILDBUCKET_READER,
                acl.LOGDOG_READER,
                acl.PROJECT_CONFIGS_READER,
                acl.SCHEDULER_READER,
            ],
            groups = "all",
        ),
        # Allow committers to use CQ and to force-trigger and stop CI builds.
        acl.entry(
            roles = [
                acl.SCHEDULER_OWNER,
                acl.CQ_COMMITTER,
            ],
            groups = [
                "project-open-codecs-committers",
                "project-open-codecs-ci-task-accounts",
            ],
        ),
        # Ability to launch CQ dry runs.
        acl.entry(
            roles = acl.CQ_DRY_RUNNER,
            groups = "project-open-codecs-tryjob-access",
        ),
        # Group with robots that have write access to the Logdog prefix.
        acl.entry(
            roles = acl.LOGDOG_WRITER,
            groups = "luci-logdog-open-codecs-writers",
        ),
    ],
)

# Required Logdog configuration.
luci.logdog(gs_bucket = "open-codecs-luci-logdog")
luci.cq(status_host = "chromium-cq-status.appspot.com")

# Bucket with post-submit builders.
luci.bucket(
    name = "ci",
    acls = [
        # Allow launching ci directly (in addition to doing it through CQ).
        acl.entry(
            roles = [acl.BUILDBUCKET_TRIGGERER, acl.SCHEDULER_TRIGGERER],
            users = ["luci-scheduler@appspot.gserviceaccount.com"],
            groups = "project-open-codecs-ci-task-accounts",
        ),
    ],
)

# Bucket with pre-submit builders.
luci.bucket(
    name = "try",
    acls = [
        # Allow launching tryjobs directly (in addition to doing it through CQ).
        acl.entry(
            roles = acl.BUILDBUCKET_TRIGGERER,
            groups = "project-open-codecs-try-task-accounts",
        ),
    ],
)

# The Milo console with all post-submit builders, referenced below.
luci.console_view(
    name = "CI Console",
    repo = REPO_URL,
    refs = [REPO_REFS],
)

# The Milo builder list with all pre-submit builders, referenced below.
luci.list_view(name = "Try Builders")

# The CQ group with all pre-submit builders, referenced below.
luci.cq_group(
    name = "MainCQ",
    watch = cq.refset(REPO_URL, refs = [REPO_REFS]),
)

# The gitiles poller: a source of commits that trigger CI builders.
luci.gitiles_poller(
    name = "open-codecs-poller",
    bucket = "ci",
    repo = REPO_URL,
    refs = [REPO_REFS],
)

def ci_builder(name, *, os, category, cpu = "x86-64"):
    """Defines a post-submit builder."""
    luci.builder(
        name = name,
        bucket = "ci",
        executable = luci.recipe(
            name = "ci_builder",
            cipd_package = RECIPE_BUNDLE,
            cipd_version = RECIPE_VERSION,
        ),
        dimensions = {
            "os": os,
            "cpu": cpu or "x86-64",
            "pool": "luci.flex.ci",
        },
        service_account = "open-codecs-ci-builder@chops-service-accounts.iam.gserviceaccount.com",
        execution_timeout = 45 * time.minute,
        # Run this builder on commits to REPO_URL.
        triggered_by = ["open-codecs-poller"],
    )

    # Add it to the console as well.
    luci.console_view_entry(
        builder = "ci/" + name,  # disambiguate by prefixing the bucket name
        console_view = "CI Console",
        category = category,
    )

# Define a xenial linux 64 builder
ci_builder("xenial", os = "Ubuntu-16.04", category = "Linux|16.04")

def try_builder(name, *, os, cpu = "x86-64"):
    """Defines a pre-submit builder."""
    luci.builder(
        name = name,
        bucket = "try",
        executable = luci.recipe(
            name = "try_builder",
            cipd_package = RECIPE_BUNDLE,
            cipd_version = RECIPE_VERSION,
        ),
        dimensions = {
            "os": os,
            "cpu": cpu or "x86-64",
            "pool": "luci.flex.try",
        },
        service_account = "open-codecs-try-builder@chops-service-accounts.iam.gserviceaccount.com",
        execution_timeout = 45 * time.minute,
    )

    # Add to the CQ.
    luci.cq_tryjob_verifier(
        builder = "try/" + name,
        cq_group = "MainCQ",
    )

    # And also to the pre-submit builders list.
    luci.list_view_entry(
        builder = "try/" + name,
        list_view = "Try Builders",
    )

# Define a xenial linux 64 builder
try_builder("xenial", os = "Ubuntu-16.04")

################################################################################
exec("recipes.star")
