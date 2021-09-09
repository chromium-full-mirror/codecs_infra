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
    api.script_wrapper(warning_threshold=1, logs=result.stdout)
"""

import re

from recipe_engine import recipe_api
from six import ensure_str


class ScriptWrapperApi(recipe_api.RecipeApi):
  """Module that wraps result logs and parses warnings."""

  re_warning = re.compile(r'^.*:\d+:\d+: warning: .*$', re.MULTILINE)

  def __call__(self, warning_threshold=0, logs=''):
    """Extracts warnings from logs.

    Fails when warning count is higher than the threshold.
    Changes step.presentation.status to WARNING if warning count is not zero.

    Args:
      warning_threshold: max count of extracted warnings.
      logs: input data for the parser. Logs can be multiline.

    Raises:
      StepFailure: error that fails the entire recipe execution.
    """
    self.m.step('Parsing Warnings',
                ['echo', 'Max of %d warnings' % warning_threshold])
    warnings = self.re_warning.findall(ensure_str(logs))
    self.m.step.active_result.presentation.logs['warnings'] = [
        'Found %d warnings during the build.\n' % len(warnings),
        'Max threshold is %d warnings.' % warning_threshold,
        'Skipping %d files.' % 0
    ] + warnings
    if not warnings:
      self.m.step.active_result.presentation.status = self.m.step.SUCCESS
    elif len(warnings) > warning_threshold:
      self.m.step.active_result.presentation.status = self.m.step.FAILURE
      # StepFailure exception is needed to fail the recipe
      raise self.m.step.StepFailure('Found %d warnings above %d threshold.' %
                                    (len(warnings), warning_threshold))
    else:
      self.m.step.active_result.presentation.status = self.m.step.WARNING
