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
CI_BUILDER_ACCOUNT = "open-codecs-ci-builder@chops-service-accounts.iam.gserviceaccount.com"
CIPD_PREFIX = "infra/recipe_bundles"
CODECS_INFRA_REPO_URL = "https://chromium.googlesource.com/codecs/infra"
LIBWEBM_REPO_URL = "https://chromium.googlesource.com/webm/libwebm"
LIBWEBP2_REPO_URL = "https://chromium.googlesource.com/codecs/libwebp2"
RECIPE_BUNDLE = "%s/chromium.googlesource.com/codecs/infra" % CIPD_PREFIX
RECIPE_VERSION = "refs/heads/main"
REPO_REFS = "refs/heads/main"
TRY_BUILDER_ACCOUNT = "open-codecs-try-builder@chops-service-accounts.iam.gserviceaccount.com"
