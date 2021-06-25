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

import re
from recipe_engine import recipe_api


class CheckoutApi(recipe_api.RecipeApi):

  def __init__(self, **kwargs):
    super(CheckoutApi, self).__init__(**kwargs)

  def ensure_checkout(self, repo=None, ref=None):
    if not ref or not repo:
      assert self.m.tryserver.is_tryserver
      assert self.m.tryserver.gerrit_change is not None
      repo = self.m.tryserver.gerrit_change_repo_url
      ref = self.m.tryserver.gerrit_change_fetch_ref

    assert re.match(r'^https://.*/(codecs|webm)/.*$', repo)
    self.m.git.checkout(repo, ref=ref)
