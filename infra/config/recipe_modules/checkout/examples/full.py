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

from PB.go.chromium.org.luci.scheduler.api.scheduler.v1 import (triggers as
                                                                triggers_pb2)

DEPS = [
    'checkout', 'recipe_engine/path', 'recipe_engine/step',
    'recipe_engine/buildbucket', 'recipe_engine/properties',
    'recipe_engine/scheduler'
]

PYTHON_VERSION_COMPATIBILITY = 'PY3'
REPO_NAMES = ['codecs/infra', 'webm/libwebm']


# NOTE: This example shows the usage of checkout module in a recipe.
def RunSteps(api):
  api.checkout.ensure_checkout()


def GenTests(api):
  yield (api.test('Throw AssertionError when empty inputs in a CI build') +
         api.expect_exception('AssertionError'))
  for repo in REPO_NAMES:
    git_repo = 'https://chromium.googlesource.com/' + repo
    yield (api.test('Ensure checkout when try builder is triggered by a %s CL' %
                    repo) + api.buildbucket.try_build(
                        project='repo',
                        bucket='try',
                        builder='linux',
                        git_repo=git_repo,
                        change_number=2974332,
                        patch_set=1))
    yield (api.test(
        'Ensure checkout when ci builder is triggered by %s scheduler' % repo) +
           api.scheduler(
               triggers=[
                   triggers_pb2.Trigger(
                       id='a',
                       gitiles=dict(
                           repo=git_repo,
                           ref='refs/heads/main',
                           revision='a' * 40,
                       ),
                   ),
               ],))

  wrong_repo = 'https://chromium.googlesource.com/angle'
  yield (api.test('AssertionError when try builder contains the wrong repo') +
         api.buildbucket.try_build(
             project='repo',
             bucket='try',
             builder='linux',
             git_repo=wrong_repo,
             change_number=2974332,
             patch_set=1) + api.expect_exception('AssertionError'))
  yield (api.test('AssertionError when ci builder contains the wrong repo') +
         api.scheduler(
             triggers=[
                 triggers_pb2.Trigger(
                     id='a',
                     gitiles=dict(
                         repo=wrong_repo,
                         ref='refs/heads/main',
                         revision='a' * 40,
                     ),
                 ),
             ],) + api.expect_exception('AssertionError'))
