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
"""Recipe module for caching cipd dependencies.

The module will download and cache cipd packages.
  DEPS = ['prerequisites', ...]
  ....
    api.prerequisites.ensure()
    assert api.path.exists(api.path['cache_dir'].join('cipd_packages'))
"""

from recipe_engine import recipe_api


class PrerequisitesApi(recipe_api.RecipeApi):
  """Caches builder dependencies."""

  def __init__(self, properties, **kwargs):
    super().__init__(**kwargs)
    self._cipd_packages = properties.cipd_package

  def ensure_tools(self):
    assert 'cache' in self.m.path and self.m.path.exists(self.m.path['cache'])
    cipd_root = self.m.path['cache'].join('cipd_packages')
    ensure_file = self.m.cipd.EnsureFile()
    cipd_paths = []
    for cipd_pkg in self._cipd_packages:
      ensure_file.add_package(cipd_pkg.package_path, cipd_pkg.version)
      cipd_paths.append('%s/%s' % (cipd_root, cipd_pkg.dest))
    self.m.cipd.ensure(cipd_root, ensure_file)
    return cipd_paths
