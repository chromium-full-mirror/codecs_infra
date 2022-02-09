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

# Load from common starlark file.
load(
    "//lib/common.star",
    "CODECS_INFRA_REPO_URL",
    "REPO_REFS",
    "TRY_BUILDER_ACCOUNT",
)

# Required depot_tools.
lucicfg.check_version("1.30.9", "Please update depot_tools")

# Use Buildbucket agent rather than deprecated kitchen.
luci.recipe.defaults.use_bbagent.set(True)

# Enable experiments
lucicfg.enable_experiment("crbug.com/1182002")
luci.builder.defaults.experiments.set(
    {
        # Use python3 on bbagent
        "luci.recipes.use_python3": 100,
    },
)

# lucicfg configuration.
lucicfg.config(
    config_dir = "generated",
    tracked_files = ["*.cfg", "**/*.template"],
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
    notify = "luci-notify.appspot.com",
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
    bindings = [
        luci.binding(
            roles = "role/configs.validator",
            users = TRY_BUILDER_ACCOUNT,
        ),
        luci.binding(
            roles = "role/swarming.poolOwner",
            groups = "project-open-codecs-admins",
        ),
        luci.binding(
            roles = "role/swarming.poolViewer",
            groups = "project-open-codecs-committers",
        ),
    ],
)

# Swarming permissions in realms.cfg.
luci.realm(name = "pools/ci")
luci.realm(name = "pools/try")

# Led users
def led_users(pool_realm, builder_realm, groups):
    luci.binding(
        roles = "role/swarming.taskTriggerer",
        realm = builder_realm,
        groups = groups,
    )
    luci.binding(
        roles = "role/swarming.poolUser",
        realm = pool_realm,
        groups = groups,
    )

led_users(
    pool_realm = "pools/try",
    builder_realm = "try",
    groups = [
        "project-open-codecs-admins",
        "project-open-codecs-tryjob-access",
    ],
)

luci.milo(
    logo =
        "https://storage.googleapis.com/downloads.webmproject.org/media/images/oc-logo-luci.svg",
)

# Required Logdog configuration.
luci.logdog(gs_bucket = "open-codecs-luci-logdog")
luci.cq(status_host = "chromium-cq-status.appspot.com")

# Bucket with post-submit builders.
luci.bucket(
    name = "ci",
    acls = [
        acl.entry(
            roles = [acl.BUILDBUCKET_TRIGGERER, acl.SCHEDULER_TRIGGERER],
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
            groups = "project-open-codecs-tryjob-access",
        ),
    ],
)

# The Milo console with all post-submit builders, referenced below.
luci.console_view(
    name = "CI Console",
    repo = CODECS_INFRA_REPO_URL,
    refs = [REPO_REFS],
)

# The Milo builder list with all pre-submit builders, referenced below.
luci.list_view(name = "Try Builders")

################################################################################
exec("subprojects/codecs_infra/codecs_infra.star")
exec("subprojects/libwebm/libwebm.star")
exec("subprojects/libwebp/libwebp.star")
exec("subprojects/libwebp2/libwebp2.star")
