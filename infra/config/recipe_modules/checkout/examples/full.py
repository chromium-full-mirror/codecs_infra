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

DEPS = [
    'checkout', 'recipe_engine/path', 'recipe_engine/step',
    'recipe_engine/buildbucket', 'recipe_engine/properties'
]

REPO_NAMES = ['codecs/infra', 'webm/libwem']


# NOTE: This example shows the usage of checkou module in a recipe.
def RunSteps(api):
  api.checkout.ensure_checkout()


def GenTests(api):
  results = api.test('gerrit checkout for all repos')
  for repo in REPO_NAMES:
    results += api.buildbucket.try_build(
        'repo',
        'linux',
        git_repo='https://chromium.googlesource.com/%s' % (repo),
        change_number=2974332,
        patch_set=1)
  yield results

  yield (api.test('gerrit with wrong repo') + api.buildbucket.try_build(
      'repo',
      'linux',
      git_repo='https://chromium.googlesource.com/angle',
      change_number=2974332,
      patch_set=1) + api.expect_exception('AssertionError'))
