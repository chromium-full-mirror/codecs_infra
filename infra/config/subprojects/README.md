Definitions of LUCI entities for the Open Codecs Projects

The following subprojects exist:

-   codecs/infra - Builders that set up LUCI Open Codecs infrastructure
    configuration from [codecs/infra](chromium.googlesource.com/codecs/infra)
    codebase.
-   libwebm - Builders that test the
    [libwebm](chromium.googlesource.com/webm/libwebm) codebase.

Each subproject contains a \<subproject\>.star that is the entry point for its
configuration, which execs the starlark files that define the LUCI entities for
the subproject.
