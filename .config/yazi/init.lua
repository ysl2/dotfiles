-- NOTE: Use `ya pkg install` to restore all packages from package.toml.

-- NOTE: `ya pkg add dedukun/relative-motions`
-- Ref: https://github.com/dedukun/relative-motions.yazi?tab=readme-ov-file#configuration
require("relative-motions"):setup({ show_numbers="relative_absolute", show_motion = true, enter_mode ="first" })
