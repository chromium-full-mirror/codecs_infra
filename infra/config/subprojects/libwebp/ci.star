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

# Libwebp sanitizer configuration matrix.
_LIBWEBP_SANITIZER_TARGETS = [
    "x86",
    "x86_64",
]
_LIBWEBP_SANITIZERS = [
    "cfi",
    "integer",
    "undefined",
]
_LIBWEBP_SANITIZERS_EXCLUDED = []

def _libwebp_sanitizers_builder(
        *,
        name,
        script_name,
        compile_targets = [],
        sanitizers = [],
        excluded_builders = [],
        properties = {},
        **kwargs):
    """Defines Libwebp sanitizer builds

    Args:
      name: name of builder
      script_name: compilation script
      sanitizers: compilation script build type list
      compile_targets: target platform list
      excluded_builders: filter list to remove builder from lucicfg
      properties: builder's input properties
      **kwargs: other keyword args
    """
    builders = []
    for target in compile_targets:
        for sanitizer in sanitizers:
            for asm_flag in ["enabled", "disabled"]:
                builder_name = "%s-%s" % (target, sanitizer)

                if asm_flag == "disabled":
                    builder_name = "%s-%s" % (builder_name, asm_flag)

                if builder_name in excluded_builders:
                    continue
                builder_name = "%s-%s" % (name, builder_name)
                overridden_properties = {
                    "script_name": script_name,
                    "script_arg": [target, sanitizer, asm_flag],
                }
                overridden_properties.update(properties)

                builders.append(
                    ci_helper.create_builder(
                        name = builder_name,
                        os = "linux",
                        properties = overridden_properties,
                        **kwargs
                    ),
                )
    return builders

libwebp_ci_builder = ci_helper.setup_builder(
    prefix = "libwebp",
    email_list = ["jzern@google.com"],
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

# Defines libwebp sanitizers.
libwebp_ci_builder(
    name = "sanitizer",
    builder_creator = _libwebp_sanitizers_builder,
    script_name = "run_sanitizer_tests.sh",
    compile_targets = _LIBWEBP_SANITIZER_TARGETS,
    sanitizers = _LIBWEBP_SANITIZERS,
    excluded_builders = _LIBWEBP_SANITIZERS_EXCLUDED,
    recipe = "run_infra_script",
    # TODO(b/185520507): enable schedule when this builder is verified.
    #schedule = "0 9 * * *",
)
