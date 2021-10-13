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
"""OpenCodecs Common Definitions
"""
ANDROID_NDK_DIR = "/opt/android-ndk/"
CI_BUILDER_ACCOUNT = "open-codecs-ci-builder@chops-service-accounts.iam.gserviceaccount.com"
CIPD_PREFIX = "infra/recipe_bundles/chromium.googlesource.com/codecs/infra"
CODECS_INFRA_REPO_URL = "https://chromium.googlesource.com/codecs/infra"
EMSDK_DIR = "/opt/emsdk/"
LIBWEBM_REPO_URL = "https://chromium.googlesource.com/webm/libwebm"
LIBWEBP_REPO_URL = "https://chromium.googlesource.com/webm/libwebp"
LIBWEBP2_REPO_URL = "https://chromium.googlesource.com/codecs/libwebp2"
RECIPE_BUNDLE = CIPD_PREFIX
RECIPE_VERSION = "refs/heads/main"
REPO_REFS = "refs/heads/main"
TRY_BUILDER_ACCOUNT = "open-codecs-try-builder@chops-service-accounts.iam.gserviceaccount.com"

# Refer to cipd dependencies from this map
CODECS_CIPD_DEPS_MAPPING = {
    "android-ndk": {
        "package_path": CIPD_PREFIX + "/android-ndk",
        "version": "latest",
        "dest": "android-ndk",
    },
    "mips-img-linux-gnu": {
        "package_path": CIPD_PREFIX + "/mips-img-linux-gnu",
        "version": "latest",
        "dest": "mips-img-linux-gnu/bin",
    },
    "mips-mti-linux-gnu": {
        "package_path": CIPD_PREFIX + "/mips-mti-linux-gnu",
        "version": "latest",
        "dest": "mips-mti-linux-gnu/bin",
    },
}
