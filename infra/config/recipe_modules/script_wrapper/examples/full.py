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
}

PYTHON_VERSION_COMPATIBILITY = 'PY3'


def RunSteps(api, logs):
  api.script_wrapper(logs=logs)


def GenTests(api):

  def CheckLogsContain(check, steps, parser, key, value):
    check(value in steps[key].logs[parser])

  def CheckLogsDontContain(check, steps, parser, key, value):
    check(value not in steps[key].logs[parser])

  invalid_warning_logs = (
      'This line test anchoring\n'
      '/b/s/w/ir/k/libwebm/testing/mkvmuxer_tests.cc:142:16: warning:')
  valid_warning_logs = (
      'This line test anchoring\n'
      '/b/s/w/ir/k/libwebm/testing/mkvmuxer_tests.cc:142:16: warning: '
      'shifting a negative signed value is undefined [-Wshift-negative-value]\n'
      'int tmp = -4 << 1; // UBSAN offending warning')
  invalid_runtime_error_logs = (
      'This line test anchoring\n'
      '/var/jenkins/workspace/libwebm__test/host/x86_64-ubsan/libwebm/testing/'
      'mkvmuxer_tests.cc:142:16: runtime error:')
  # pylint: disable= inconsistent-quotes
  valid_runtime_error_logs = (
      "This line test anchoring\n"
      " ../aom/aom_dsp/x86/synonyms.h:30:28: runtime error: load of misaligned "
      "address 0x08ff0b02 for type 'const uint32_t' (aka 'const unsigned int'),"
      " which requires 4 byte alignment\n"
      " ../libvpx/test/convolve_test.cc:325:10: runtime error: signed integer "
      "overflow: 2147483647 + 1 cannot be represented in type 'int'\n")

  yield api.test('Empty results') + api.script_wrapper()

  invalid_parser = {'name': 'invalid', 'threshold': 0}
  yield (api.test('Throw AssertionError when parser threshold is invalid') +
         api.properties(logs=valid_warning_logs) +
         api.script_wrapper(script_parsers=[invalid_parser]) +
         api.expect_exception('AssertionError'))

  parameterized_input = {
      'warnings': [invalid_warning_logs, valid_warning_logs],
      'runtime errors': [invalid_runtime_error_logs, valid_runtime_error_logs]
  }

  for parser, logs in parameterized_input.items():
    step_name = 'Parsing ' + parser
    fmt = {'parser': parser}
    invalid_logs = logs[0]
    valid_logs = logs[1]

    parsers = [
        {
            'name': parser,
            'threshold': 0
        },
    ]
    yield (
        api.test('Parsing 0 %(parser)s results' % fmt) +
        api.properties(logs=invalid_logs) +
        api.script_wrapper(script_parsers=parsers) +
        api.post_check(CheckLogsDontContain, parser, step_name,
                       invalid_logs.splitlines()[1]) +
        api.post_check(StepCommandRE, step_name, [
            'echo', 'Parsing %(parser)s. Threshold: 0 %(parser)s' % fmt
        ]) + api.post_process(StepSuccess, step_name))

    parsers[0]['threshold'] = 10
    yield (api.test('Parsing results below %(parser)s threshold' % fmt) +
           api.properties(logs=valid_logs) +
           api.script_wrapper(script_parsers=parsers) +
           api.post_check(CheckLogsContain, parser, step_name,
                          valid_logs.splitlines()[1]) +
           api.post_check(
               StepCommandRE, step_name,
               ['echo',
                'Parsing %(parser)s. Threshold: 10 %(parser)s' % fmt]) +
           api.post_process(StepWarning, step_name))

    parsers[0]['threshold'] = 0
    yield (
        api.test('Parsing results above %(parser)s threshold' % fmt) +
        api.properties(logs=valid_logs) +
        api.script_wrapper(script_parsers=parsers) +
        api.post_check(CheckLogsContain, parser, step_name,
                       valid_logs.splitlines()[1]) +
        api.post_check(StepCommandRE, step_name, [
            'echo', 'Parsing %(parser)s. Threshold: 0 %(parser)s' % fmt
        ]) + api.post_process(StepFailure, step_name) +
        api.post_process(StatusFailure))

  all_logs = '\n'.join([
      valid_warning_logs, invalid_warning_logs, valid_runtime_error_logs,
      invalid_runtime_error_logs
  ])

  parsers = [{
      'name': k,
      'threshold': 0
  } for k, _ in parameterized_input.items()]
  yield (api.test('Throw StepFailure if any parser finds matches') +
         api.properties(logs=all_logs) +
         api.script_wrapper(script_parsers=parsers) +
         api.post_process(StepFailure, 'Parsing warnings') +
         api.post_process(StepFailure, 'Parsing runtime errors') +
         api.post_process(StatusFailure))

  # pylint: disable= inconsistent-quotes
  exclude_logs = (
      " ../../../libwebp/src/dsp/dec_sse2.c:605:5: runtime error: store to "
      "misaligned address 0x00000319e322 for type 'int32_t' (aka 'int'), which "
      "requires 4 byte alignment\n"
      " ../libvpx/vp9/encoder/x86/vp9_variance_sse2.c:32:42: runtime error: "
      "load of misaligned address 0x08aabe3a for type 'const uint32_t' (aka "
      "'const unsigned int'), which requires 4 byte alignment\n"
      " ../libvpx/test/../third_party/libwebm/mkvparser.cpp:248:12: runtime "
      "error: left shift of negative value -128\n"
      " /usr/lib/gcc/x86_64-linux-gnu/4.7/../../../../include/c++/4.7/bits/"
      "ios_base.h:98:24: runtime error: load of value 4294967221, which is not "
      "a valid value for type 'std::_Ios_Fmtflags'\n"
      " /usr/lib/gcc/x86_64-linux-gnu/6.3.0/../../../../include/c++/6.3.0/bits/"
      "basic_string.h:352:51: runtime error: unsigned integer overflow: 18 - 22"
      " cannot be represented in type 'unsigned long'")

  fmt = {'parser': 'runtime errors', 'skips': 5}
  runtime_parser = {'name': 'runtime errors', 'threshold': 0}
  yield (api.test('Exclude all logs matching exclude_filter') +
         api.properties(logs=exclude_logs) +
         api.script_wrapper(script_parsers=[runtime_parser]) + api.post_check(
             CheckLogsDontContain, 'runtime errors', 'Parsing runtime errors',
             exclude_logs.splitlines()[1]) + api.post_check(
                 CheckLogsContain, 'runtime errors', 'Parsing runtime errors',
                 'Filtering %(skips)d %(parser)s.' % fmt) +
         api.post_process(StepSuccess, 'Parsing runtime errors'))
