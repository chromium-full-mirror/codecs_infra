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

from PB.recipes.codecs.input_properties import InputProperties
from recipe_engine.post_process import StepCommandRE, DropExpectation

DEPS = [
    'checkout',
    'recipe_engine/step',
    'recipe_engine/buildbucket',
    'recipe_engine/properties',
    'recipe_engine/path',
    'recipe_engine/context',
]
PROPERTIES = InputProperties


def RunSteps(api, properties):
  api.step('git checkout', ['echo', 'git checkout'])
  api.checkout.ensure_checkout()

  script_name = properties.script_name
  script_args = list(properties.script_arg)
  script_path = api.path['checkout'].join('infra', script_name)

  if not api.path.exists(script_path):
    api.step('Script not found', ['echo', '%s not found.' % script_path])
    api.step(
        'Failed to find script, %s, is not a part of this branch' % script_name,
        ['false'])
    return

  with api.context(cwd=api.path['checkout'], env=properties.env):
    api.step('Script found', ['echo', '%s found.' % script_path])
    api.step('Running %s %s' % (script_name, ' '.join(script_args)),
             ['bash', '-xe', script_path] + script_args)


def GenTests(api):
  yield (api.test('Infra script does not exist') + api.buildbucket.try_build(
      'repo',
      'linux',
      git_repo='https://chromium.googlesource.com/webm/libwebm',
      change_number=405009,
      patch_set=1) + api.properties(
          InputProperties(
              script_name='compile.sh', script_arg=['some', 'args'])) +
         api.post_process(StepCommandRE, 'Script not found',
                          ['echo', '.*/infra/compile.sh not found.']) +
         api.post_process(
             StepCommandRE,
             'Failed to find script, compile.sh, is not a part of this branch',
             ['false']))
  yield (
      api.test('Infra script does exist') + api.buildbucket.try_build(
          'repo',
          'linux',
          git_repo='https://chromium.googlesource.com/webm/libwebm',
          change_number=405009,
          patch_set=1) + api.properties(
              InputProperties(
                  script_name='compile.sh', script_arg=['some', 'args'])) +
      api.path.exists(api.path['checkout'].join('infra', 'compile.sh')) +
      api.post_process(StepCommandRE, 'Script found',
                       ['echo', '.*/infra/compile.sh found.']) +
      api.post_process(StepCommandRE, 'Running compile.sh some args',
                       ['bash', '-xe', '.*/infra/compile.sh', 'some', 'args']))
