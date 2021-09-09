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
"""Recipe example for script_wrapper recipe_module.

Recipe to run tests and shows usage of script_wrapper recipe_module.
Test: ./recipes.py test train --filter script_wrapper
"""

from recipe_engine.post_process import (StatusFailure, StepCommandRE,
                                        StepFailure, StepSuccess, StepWarning)
from recipe_engine.recipe_api import Property

DEPS = [
    'script_wrapper',
    'recipe_engine/properties',
]

PROPERTIES = {
    'logs': Property(kind=str, default=''),
    'warning_threshold': Property(kind=int, default=0),
}
PYTHON_VERSION_COMPATIBILITY = 'PY3'


def RunSteps(api, warning_threshold, logs):
  api.script_wrapper(warning_threshold=warning_threshold, logs=logs)


def GenTests(api):

  def CheckLogsContain(check, steps, key, value):
    check(value in steps[key].logs['warnings'])

  def CheckLogsDontContain(check, steps, key, value):
    check(value not in steps[key].logs['warnings'])

  invalid_warning_logs = (
      'This line test anchoring\n'
      '/b/s/w/ir/k/libwebm/testing/mkvmuxer_tests.cc:142:16: warning:')
  valid_warning_logs = (
      'This line test anchoring\n'
      '/b/s/w/ir/k/libwebm/testing/mkvmuxer_tests.cc:142:16: warning: '
      'shifting a negative signed value is undefined [-Wshift-negative-value]\n'
      'int tmp = -4 << 1; // UBSAN offending warning')
  yield (api.test('Empty results') + api.post_check(
      StepCommandRE, 'Parsing Warnings', ['echo', 'Max of 0 warnings']) +
         api.post_process(StepSuccess, 'Parsing Warnings'))
  yield (api.test('0 Warning results') +
         api.properties(logs=invalid_warning_logs, warning_threshold=0) +
         api.post_check(CheckLogsDontContain, 'Parsing Warnings',
                        invalid_warning_logs.splitlines()[1]) +
         api.post_process(StepSuccess, 'Parsing Warnings'))
  yield (api.test('Warning results below threshold') +
         api.properties(logs=valid_warning_logs, warning_threshold=2) +
         api.post_check(CheckLogsContain, 'Parsing Warnings',
                        valid_warning_logs.splitlines()[1]) +
         api.post_check(StepCommandRE, 'Parsing Warnings',
                        ['echo', 'Max of 2 warnings']) +
         api.post_process(StepWarning, 'Parsing Warnings'))
  yield (api.test('Warnings above threshold') +
         api.properties(logs=valid_warning_logs, warning_threshold=0) +
         api.post_check(CheckLogsContain, 'Parsing Warnings',
                        valid_warning_logs.splitlines()[1]) +
         api.post_check(StepCommandRE, 'Parsing Warnings',
                        ['echo', 'Max of 0 warnings']) +
         api.post_process(StepFailure, 'Parsing Warnings') +
         api.post_process(StatusFailure))
