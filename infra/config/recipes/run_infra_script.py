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

from google.protobuf.internal.containers import ScalarMap
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
PYTHON_VERSION_COMPATIBILITY = "PY3"

_INFRA_DIRECTORIES = ['infra', 'presubmit']


def _FindScriptInDir(path, root_dir, script_name):
  for directory in _INFRA_DIRECTORIES:
    script_path = root_dir.join(directory, script_name)
    if path.exists(script_path):
      return True, script_path
  return False, ''


def RunSteps(api, properties):
  api.step('git checkout', ['echo', 'git checkout'])
  api.checkout.ensure_checkout()

  script_name = properties.script_name
  script_args = list(properties.script_arg)
  script_found, script_path = _FindScriptInDir(api.path, api.path['checkout'],
                                               script_name)

  if not script_found:
    api.step('Script not found', ['echo', '%s not found.' % script_name])
    api.step(
        'Failed to find script, %s, is not a part of this branch' % script_name,
        ['false'])
    return

  # properties.env is ScalarMap {unicode: str} and context accepts
  # dict {str: str}.
  assert isinstance (properties.env, ScalarMap)
  env_vars = {str(k): v for k, v in properties.env.items()}

  with api.context(cwd=api.path['checkout'], env=env_vars):
    api.step('Script found', ['echo', '%s found.' % script_path])
    api.step('Running %s %s' % (script_name, ' '.join(script_args)),
             ['bash', '-xe', script_path] + script_args)


def GenTests(api):
  for infra_dir in _INFRA_DIRECTORIES:
    yield (
        api.test('Infra script does not exist in %s' % infra_dir) +
        api.buildbucket.try_build(
            'repo',
            'linux',
            git_repo='https://chromium.googlesource.com/webm/libwebm',
            change_number=405009,
            patch_set=1) + api.properties(
                InputProperties(
                    script_name='compile.sh', script_arg=['some', 'args']),
                env={'PATH': '/opt/android-ndk/:%(PATH)s'}) +
        api.post_process(StepCommandRE, 'Script not found',
                         ['echo', 'compile.sh not found.']) +
        api.post_process(
            StepCommandRE,
            'Failed to find script, compile.sh, is not a part of this branch',
            ['false']))
    yield (api.test('Infra script does exist in %s' % infra_dir) +
           api.buildbucket.try_build(
               'repo',
               'linux',
               git_repo='https://chromium.googlesource.com/webm/libwebm',
               change_number=405009,
               patch_set=1) + api.properties(
                   InputProperties(
                       script_name='compile.sh', script_arg=['some', 'args']),
                   env={'PATH': '/opt/android-ndk/:%(PATH)s'}) +
           api.path.exists(api.path['checkout'].join(infra_dir, 'compile.sh')) +
           api.post_process(StepCommandRE, 'Script found',
                            ['echo', '.*/*/compile.sh found.']) +
           api.post_process(StepCommandRE, 'Running compile.sh some args',
                            ['bash', '-xe', '.*/*/compile.sh', 'some', 'args']))
