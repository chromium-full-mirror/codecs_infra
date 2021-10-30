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
"""Top-level presubmit script for codecs/infra.

See https://dev.chromium.org/developers/how-tos/depottools/presubmit-scripts for
details on the presubmit API built into depot_tools.
"""

USE_PYTHON3 = True
_CODECS_INFRA_MAX_LINE_LENGTH = 80


def _GetFilesToSkip(input_api):
  return list(input_api.DEFAULT_FILES_TO_SKIP) + [
      r".*recipes.py$",
      # Exclude all "...recipe_deps" directories.
      #
      # These directories are created by recipe engine.
      # Each is an independent recipe checkout. If Pylint is run on
      # these, it will hang forever, so we must exclude them.
      r"^(.*/)?\..*recipe_deps/.*",
      # Exclude generated files by lucicfg.
      r".*/generated/.*\.cfg",
  ]


def _SourceFileFilter(input_api, files_to_check=None, files_to_skip=None):
  return lambda x: input_api.FilterSourceFile(
      x, files_to_check=files_to_check, files_to_skip=files_to_skip)


def CommonChecks(input_api, output_api):
  results = []

  results.extend(
      input_api.canned_checks.CheckPatchFormatted(
          input_api,
          output_api,
          check_clang_format=False,
          result_factory=output_api.PresubmitError))
  results.extend(
      input_api.canned_checks.CheckChangeHasNoCrAndHasOnlyOneEol(
          input_api, output_api))
  results.extend(
      input_api.canned_checks.CheckChangeHasNoTabs(input_api, output_api))
  results.extend(
      input_api.canned_checks.CheckChangeHasNoStrayWhitespace(
          input_api, output_api))

  source_file_filter = _SourceFileFilter(
      input_api, files_to_skip=_GetFilesToSkip(input_api))
  results.extend(
      input_api.canned_checks.CheckLongLines(
          input_api,
          output_api,
          maxlen=_CODECS_INFRA_MAX_LINE_LENGTH,
          source_file_filter=source_file_filter))

  tests = []

  # Verify *.cfg match original *.star. Has trouble working on Win.
  if not input_api.is_windows:
    tests.extend(
        input_api.canned_checks.CheckLucicfgGenOutput(input_api, output_api,
                                                      "main.star"))

  # Run Lucicfg lint and fmt.
  results.extend(
      input_api.RunTests([
          input_api.Command(
              name="lucicfg lint",
              cmd=["lucicfg", "lint",
                   input_api.PresubmitLocalPath()],
              kwargs={},
              message=output_api.PresubmitError),
          input_api.Command(
              name="lucicfg fmt",
              cmd=["lucicfg", "fmt", "-dry-run"],
              kwargs={},
              message=output_api.PresubmitError)
      ]))

  # Run pylint.
  results.extend(
      input_api.canned_checks.RunPylint(
          input_api,
          output_api,
          files_to_skip=_GetFilesToSkip(input_api),
          pylintrc=".pylintrc",
          version="2.7"))

  results.extend(input_api.RunTests(tests))
  return results


def CheckChangeOnUpload(input_api, output_api):
  return CommonChecks(input_api, output_api)


def CheckChangeOnCommit(input_api, output_api):
  return CommonChecks(input_api, output_api)
