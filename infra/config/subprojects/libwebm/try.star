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
    "i686-w64-mingw32": "i686-w64-mingw32",
    "x86_64-linux-clang": "native-clang",
    "x86_64-linux-gnu": "native",
    "x86_64-linux-gnu-make": "native-Makefile.unix",
    "x86_64-w64-mingw32": "x86_64-w64-mingw32",
}

# Libwebm compile android configuration matrix.
_LIBWEBM_COMPILE_ANDROID_BUILD_TYPES = ["release", "debug"]
_LIBWEBM_COMPILE_ANDROID_TARGETS = {
    "arm64-v8a-android": "arm64-v8a",
    "armeabi-v7a-android": "armeabi-v7a",
    "x86-android": "x86",
    "x86_64-android": "x86_64",
}

# Libwebm test configuration matrix.
_LIBWEBM_TEST_SANITIZERS = ["asan", "ubsan", "valgrind"]
_LIBWEBM_TEST_TARGETS = ["x86", "x86_64"]

def _libwebm_compile_builder(
        *,
        name,
        script_name,
        build_types = [],
        compile_targets = {},
        **kwargs):
    """Defines Libwebm compiler builds

    Args:
      name: name of builder
      script_name: compilation script
      build_types: compilation script build type list
      compile_targets: host platform to cross-compile map
      **kwargs: other keywords args
    """
    builders = []
    for config in build_types:
        for host, target in compile_targets.items():
            build_type = "-debug" if "debug" in config else ""
            builder_name = "%s-%s%s" % (name, host, build_type)
            properties = {
                "script_name": script_name,
                "script_arg": [config, target],
                "env": {
                    "PATH": "%(PATH)s:/opt/android-ndk/",
                },
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

def _libwebm_test_builder(
        *,
        name,
        script_name,
        sanitizers = [],
        test_targets = {},
        **kwargs):
    """Defines Libwebm unit test builds

    Args:
      name: name of builder
      script_name: test script
      sanitizers: test script sanitizer list
      test_targets: host platform to cross-compile list
      **kwargs: other keywords args
    """
    builders = []
    for sanitizer in sanitizers:
        for target in test_targets:
            builder_name = "%s-%s-%s" % (name, target, sanitizer)
            properties = {
                "script_name": script_name,
                "script_arg": ["%s-%s" % (target, sanitizer)],
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

libwebm_try_builder = try_helper.setup_builder(
    prefix = "libwebm",
    repo = LIBWEBM_REPO_URL,
    refs = [REPO_REFS],
)

# Defines libwebm builds for unix-based and mingw cross-compiled platforms.
# e.g.:
# - libwebm-compile-x86_64-linux-clang
# - libwebm-compile-x86_64-linux-clang-debug
# For more details, please refer to infra/config/generated/commit-queue.cfg.
libwebm_try_builder(
    name = "compile",
    builder_creator = _libwebm_compile_builder,
    script_name = "compile.sh",
    build_types = _LIBWEBM_COMPILE_BUILD_TYPES,
    compile_targets = _LIBWEBM_COMPILE_TARGETS,
    recipe = "run_infra_script",
)

# Defines libwebm builds for android-based platforms.
# e.g.:
#  - libwebm-compile-arm64-v8a-android
#  - libwebm-compile-arm64-v8a-android-debug
# For more details, please refer to infra/config/generated/commit-queue.cfg.
libwebm_try_builder(
    name = "compile",
    builder_creator = _libwebm_compile_builder,
    script_name = "compile_android.sh",
    build_types = _LIBWEBM_COMPILE_ANDROID_BUILD_TYPES,
    compile_targets = _LIBWEBM_COMPILE_ANDROID_TARGETS,
    recipe = "run_infra_script",
)

# Defines libwebm googletests and run-time checks.
# e.g:
# - libwebm-tests-x86-asan
# - libwebm-tests-x86_64-asan
# For more details, please refer to infra/config/generated/commit-queue.cfg.
libwebm_try_builder(
    name = "tests",
    builder_creator = _libwebm_test_builder,
    script_name = "run_unit_tests.sh",
    sanitizers = _LIBWEBM_TEST_SANITIZERS,
    test_targets = _LIBWEBM_TEST_TARGETS,
    recipe = "run_infra_script",
)

# Style-check and patch check builder for libwebm.
libwebm_try_builder(
    name = "patch-check",
    builder_creator = try_helper.patch_check_builder,
)
