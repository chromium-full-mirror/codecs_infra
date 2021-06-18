The configuration rooted at main.star defines the LUCI services configuration
for the Open Codecs project on the production instance of LUCI. The
configuration is responsible for generating the raw configuration files that do
not end in -dev.cfg as well as the markdown file cq-builders.md. Starlark files
in the following directories are consumed by the configuration:

-   lib - Utilities for defining LUCI entities such as ci builders, try
    builders, and common definitions
-   subprojects - Definitions of LUCI entities. Each subproject corresponds to a
    repo
