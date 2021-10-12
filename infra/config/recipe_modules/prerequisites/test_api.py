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
"""Mock recipe to test Prerequisites recipe module."""
from PB.recipe_modules.codecs.prerequisites.properties import InputProperties
from PB.recipe_modules.codecs.prerequisites.properties import CIPDPackage
from recipe_engine import recipe_test_api


class PrerequisitesTestApi(recipe_test_api.RecipeTestApi):
  """Prerequisites mock."""

  def __call__(self, cipd_packages=None):
    if not cipd_packages:
      cipd_packages = []
    cipd_packages = [CIPDPackage(**pkg) for pkg in cipd_packages]
    return self.m.properties(**{
        '$codecs/prerequisites': InputProperties(cipd_package=cipd_packages),
    })
