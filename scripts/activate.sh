#!/bin/bash
# This script is automatically sourced when the Pixi environment activates (e.g., during 'pixi shell' or 'pixi run')
if [ -f "$PIXI_PROJECT_ROOT/install/setup.bash" ]; then
    source "$PIXI_PROJECT_ROOT/install/setup.bash"
fi
