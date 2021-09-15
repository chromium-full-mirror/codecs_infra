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
"""Recipe module for extracting warnings logs.

The module can inspect plain text or api.step results.

  Example with step output:
  DEPS = ['script_wrapper', ...]
  ....
    result = api.step('some step', stdout=api.raw_io())
    api.script_wrapper(thresholds={'warnings': 1}, logs=result.stdout)
"""

import re

from recipe_engine import recipe_api
from six import ensure_str


class Parser(object):
  """Parser object."""

  def __init__(self, name, parser_filter):
    self._name = name
    self._parser_filter = parser_filter

  @property
  def name(self):
    return self._name

  @property
  def parser_filter(self):
    return self._parser_filter


class ScriptWrapperApi(recipe_api.RecipeApi):
  """Module that wraps result logs and parses warnings and runtime errors."""

  def __init__(self, **kwargs):
    super().__init__(**kwargs)
    self._parsers = {
        parser.name: parser for parser in [
            Parser(
                'warnings',
                re.compile(r'^(.+?):(\d+):(?:(\d+):)? ?([wW]arning): (.*)$',
                           re.MULTILINE)),
            Parser(
                'runtime errors',
                re.compile(r'^(.+?):(\d+):(?:(\d+):)? ?(runtime error): (.*)$',
                           re.MULTILINE)),
        ]
    }

  def __call__(self, logs, thresholds=None):
    """Extracts warnings and/or runtime errors from logs.

    Fails the recipe when the parser match count is higher than the threshold.

    Args:
      logs: input data for the parser. Logs can be multiline.
      thresholds: map of parser to threshold count pairs.

    Raises:
      StepFailure: error that fails the entire recipe execution.
      AssertionError: error when parser is not supported.
    """
    if not thresholds:
      return
    parsing_errors = []
    for parser, threshold in thresholds.items():
      assert parser in self._parsers.keys()
      parsing_errors.extend(
          self._does_exceed_threshold(logs, self._parsers[parser], threshold))

    if parsing_errors:
      # StepFailure exception is needed to fail the recipe.
      raise self.m.step.StepFailure('\n'.join(parsing_errors))

  def _does_exceed_threshold(self, logs, parser, threshold):
    """Extracts matches from logs and compares with threshold.

    Fails when warning count is higher than the threshold.
    Changes step.presentation.status to WARNING if warning count is not zero.

    Args:
      logs: input data for the parser. Logs can be multiline.
      parser: parser object.
      threshold: max count of extracted matches from a given parser.

    Return:
      A list of error messages.
    """
    fmt = {'parser': parser.name, 'threshold': threshold}
    self.m.step('Parsing %(parser)s' % fmt, [
        'echo',
        'Parsing %(parser)s. Threshold: %(threshold)d %(parser)s' % fmt
    ])
    matches = parser.parser_filter.findall(ensure_str(logs))
    total_matches = len(matches)

    result_logs = []
    for m in matches:
      filename, line, col, log, message = m
      filename.replace('../', '')
      if self._exclude_filter(filename, message):
        continue

      if 'libwebp' in filename or 'libvpx' in filename:
        message = message.replace(r'address 0x[A-Fa-f0-9]+',
                                  'address <redacted>')
      result_logs.append('%s:%s:%s: %s: %s' %
                         (filename, line, col, log, message))

    fmt['matches'] = len(result_logs)
    fmt['skips'] = total_matches - fmt['matches']
    self.m.step.active_result.presentation.logs[parser.name] = [
        'Parser found %(matches)d %(parser)s during the build.\n' % fmt,
        'Max threshold is %(threshold)d %(parser)s.' % fmt,
        'Filtering %(skips)d %(parser)s.' % fmt
    ] + result_logs
    if not fmt['matches']:
      self.m.step.active_result.presentation.status = self.m.step.SUCCESS
    elif fmt['matches'] > threshold:
      self.m.step.active_result.presentation.status = self.m.step.FAILURE
      parsing_error = ('Found %(matches)d %(parser)s above %(threshold)d '
                       'threshold.') % fmt
      return [parsing_error]
    else:
      self.m.step.active_result.presentation.status = self.m.step.WARNING
    return []

  @staticmethod
  def _exclude_filter(filename, message):
    """Filter-out log matches by message and filename patterns.

       Args:
        filename: filename and path from log.
        message: log message

      Returns:
        Log matches filter out when True, False otherwise.
    """
    filename.replace('../', '')
    if re.match(r'.*_(avx2|sse4|ssse3|sse2)\.c',
                filename) and ('store to misaligned' in message or
                               'load of misaligned' in message):
      return True
    elif 'third_party/' in filename:
      return True
    elif 'bits/ios_base.h' in filename and re.match(
        r'.*load of value.*std::_Ios_Fmtflags.*', message):
      return True
    elif 'bits/basic_string.h' in filename and re.match(
        r'.*unsigned integer overflow: .*', message):
      return True
    return False
