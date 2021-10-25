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
"""Try builder for codecs/infra.

Runs recipe tests individually for better inspection. As a requirement, any
changes in recipes will change the *.expected files.
"""

import copy
from recipe_engine.post_process import StepCommandRE, StatusException

DEPS = [
    'checkout',
    'recipe_engine/buildbucket',
    'recipe_engine/context',
    'recipe_engine/path',
    'recipe_engine/raw_io',
    'recipe_engine/step',
]
PYTHON_VERSION_COMPATIBILITY = 'PY3'


def RunSteps(api):
  api.step('Checkout codecs infra', cmd=None)
  api.checkout.ensure_checkout()
  recipes_dir = api.path['checkout'].join('infra', 'config')
  api.step('Find recipes.py', cmd=None)
  if not api.path.exists(recipes_dir):
    api.step.active_result.presentation.status = api.step.EXCEPTION
    raise api.step.InfraFailure('%s does not exist' % recipes_dir)
  with api.context(cwd=recipes_dir):
    api.step('Fetch deps', ['./recipes.py', 'fetch'])
    api.step(
        'List tests', ['./recipes.py', 'test', 'list'],
        stdout=api.raw_io.output(name='stdout', add_output_log=True))
    recipe_tests = copy.copy(api.step.active_result.stdout)
    recipe_tests = [
        recipe_test.decode('utf-8')
        for recipe_test in recipe_tests.splitlines()
    ]
    with api.step.nest('Run all tests', status='worst'):
      for recipe_test in recipe_tests:
        api.step('Run test %s' % recipe_test, [
            './recipes.py', 'test', 'run', '--full-stacks', '--py3-details',
            '--filter', recipe_test
        ])


def GenTests(api):
  try_build = api.buildbucket.try_build(
      'repo',
      'linux',
      git_repo='https://chromium.googlesource.com/codecs/infra',
      change_number=405009,
      patch_set=1)
  yield (api.test('infra/config/recipes.py does not exist') + try_build +
         api.post_process(StatusException))
  yield (
      api.test('Run all tests') +
      try_build + api.path.exists(api.path['checkout'].join(
          'infra', 'config', 'recipes.py')) + api.step_data(
              'List tests',
              stdout=api.raw_io.output(
                  'checkout:examples/full', name='stdout', retcode=0)) +
      api.post_check(StepCommandRE, 'Fetch deps', ['./recipes.py', 'fetch']) +
      api.post_check(StepCommandRE, 'List tests',
                     ['./recipes.py', 'test', 'list']) +
      api.post_check(StepCommandRE, 'Run all tests', []) +
      api.post_check(StepCommandRE, 'Run all tests.Run test checkout:examples/'
                     'full', [
                         './recipes.py', 'test', 'run', '--full-stacks',
                         '--py3-details', '--filter', '.*'
                     ]))
