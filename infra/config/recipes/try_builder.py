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

from recipe_engine.post_process import StepCommandRE, DropExpectation

DEPS = ['recipe_engine/step']
PYTHON_VERSION_COMPATIBILITY = 'PY3'


def RunSteps(api):
  api.step('Print Hello World', ['echo', 'hello', 'try_builder'])


def GenTests(api):
  yield (api.test('basic') + api.post_process(
      StepCommandRE, 'Print Hello World', ['echo', 'hello', 'try_builder']) +
         api.post_process(DropExpectation))
