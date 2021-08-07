#!/bin/sh

#  pre_compile.sh
#  JittyRunner
#
#  Created by Kamaal M Farah on 07/08/2021.
#  

if which swiftlint >/dev/null; then
  swiftlint
else
  echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
fi
