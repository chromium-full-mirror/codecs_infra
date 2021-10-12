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
"""Recipe example for prerequisites recipe_module.

Recipe that runs test examples and shows usage of prerequisites recipe_module.
Test: ./recipes.py test train --filter prerequisites
"""
from recipe_engine.post_process import StepCommandRE

DEPS = [
    'prerequisites',
    'recipe_engine/path',
    'recipe_engine/step',
]

PYTHON_VERSION_COMPATIBILITY = 'PY3'


# NOTE: This example shows the usage of prerequisites module in a recipe.
def RunSteps(api):
  cipd_paths = api.prerequisites.ensure_tools()
  for cipd_path in cipd_paths:
    api.step('Found %s installed' % cipd_path, [])


def GenTests(api):
  yield (api.test('AssertionError when cache dir does not exist') +
         api.expect_exception('AssertionError'))
  yield (api.test('Do nothing when properties are empty') +
         api.path.exists(api.path['cache'].join('cipd_packages')) +
         api.prerequisites())
  cipd_packages = [
      {
          'package_path': 'codecs/infra/android-ndk',
          'version': 'latest',
          'dest': 'android-ndk'
      },
      {
          'package_path': 'codecs/infra/mips-img-linux-gnu',
          'version': 'latest',
          'dest': 'mips-img-linux-gnu/bin'
      },
      {
          'package_path': 'codecs/infra/mips-mti-linux-gnu',
          'version': 'latest',
          'dest': 'mips-mti-linux-gnu/bin'
      },
  ]
  yield (
      api.test('Download packages') +
      api.prerequisites(cipd_packages=cipd_packages) +
      api.path.exists(api.path['cache'].join('cipd_packages')) +
      api.post_process(
          StepCommandRE,
          'Found [CACHE]/cipd_packages/mips-img-linux-gnu/bin installed', []))
