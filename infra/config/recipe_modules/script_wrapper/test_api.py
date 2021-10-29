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
"""Mock recipe to test ScriptWrapper recipe module."""
from PB.recipe_modules.codecs.script_wrapper.properties import InputProperties
from PB.recipe_modules.codecs.script_wrapper.properties import ScriptParser
from recipe_engine import recipe_test_api


class ScriptWrapperTestApi(recipe_test_api.RecipeTestApi):
  """ScriptWrapper mock."""

  def __call__(self, script_parsers=None):
    if not script_parsers:
      script_parsers = []
    script_parsers = [
        ScriptParser(**script_parser) for script_parser in script_parsers
    ]
    return self.m.properties(**{
        '$codecs/script_wrapper': InputProperties(script_parser=script_parsers),
    })
