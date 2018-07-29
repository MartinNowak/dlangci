#!/bin/bash

cat << 'EOF'
steps:
  - command: |
      uname -a
      make --version
      \${SHELL} --version || true
      c++ --version
      ld -v
      ! command -v gdb &>/dev/null || gdb --version
      dmd --version || true
    label: "Print envs"

  - command: |
        # just to be sure there isn't anything old left
        git clean -ffdxq .
        # make sure the entire CI folder is loaded
        if [ ! -d buildkite ] ; then
           mkdir -p buildkite && pushd buildkite
           wget https://github.com/dlang/ci/archive/master.tar.gz
           tar xvfz master.tar.gz --strip-components=2 ci-master/buildkite
           rm -rf master.tar.gz && popd
        fi
        ./buildkite/build_distribution.sh
    label: "Build"
    artifact_paths: "distribution.tar.xz"

  - wait
EOF

################################################################################
# Add your project here.
# By default, the Project Tester will perform your Travis 'script' tests.
# If a different action is preferred, set it in buildkite/build_project.sh
################################################################################
projects=(
    # sorted by test time fast to slow (to minimize pending queue length)
    "vibe-d/vibe.d+libevent-examples" # 12m1s
    "vibe-d/vibe.d+vibe-core-examples" # 9m51s
    "vibe-d/vibe.d+libevent-tests" # 8m35s
    "vibe-d/vibe.d+vibe-core-tests" # 6m44s
    "vibe-d/vibe.d+libevent-base" # 4m20s
    "vibe-d/vibe.d+vibe-core-base" # 4m31s
    # https://github.com/vibe-d/vibe.d/issues/2157
    "vibe-d/vibe.d+libasync-base" # 3m45s
    "sociomantic-tsunami/ocean" # 4m49s
    "dlang/dub" # 3m55s
    "vibe-d/vibe-core+epoll" # 3m38s
    "vibe-d/vibe-core+select" # 3m30s
    "higgsjs/Higgs" # 3m10s
    "rejectedsoftware/ddox" # 2m42s
    "BlackEdder/ggplotd" # 1m56s
    "eBay/tsv-utils" # 1m41s
    "dlang-community/D-Scanner" # 1m40s
    "dlang-tour/core" # 1m17s
    "d-widget-toolkit/dwt" # 1m16s
    "rejectedsoftware/diet-ng" # 56s
    "mbierlee/poodinis" # 40s
   #"dlang/tools" # 40s
    "atilaneves/unit-threaded" #36s
    "d-gamedev-team/gfm" # 28s
    "dlang-community/DCD" # 23s
    "weka-io/mecca" # 22s
    "CyberShadow/ae" # 22s
    "libmir/mir-algorithm" # 17s
    "dlang-community/D-YAML" # 15s
    "libmir/mir-random" # 13s
    "dlang-community/libdparse" # 13s
    "BBasile/iz" # 12s
    "dlang-community/dfmt" # 11s
    # run in under 10s sorted alphabetically
    "Abscissa/libInputVisitor"
    "ariovistus/pyd"
    "atilaneves/automem"
    "AuburnSounds/intel-intrinsics"
    "DerelictOrg/DerelictFT"
    "DerelictOrg/DerelictGL3"
    "DerelictOrg/DerelictGLFW3"
    "DerelictOrg/DerelictSDL2"
    "dlang-bots/dlang-bot"
    "dlang-community/containers"
    "dlang/undeaD"
    "DlangScience/scid"
    "ikod/dlang-requests"
    "kaleidicassociates/excel-d"
    "kaleidicassociates/lubeck"
    "kyllingstad/zmqd"
    "lgvz/imageformats"
    "libmir/mir"
    "msoucy/dproto"
    "Netflix/vectorflow"
    "nomad-software/dunit"
    "PhilippeSigaud/Pegged"
    "repeatedly/mustache-d"
    "s-ludwig/std_data_json"
    "s-ludwig/taggedalgebraic"
)
# Add all projects that require more than 3GB of memory to build
declare -A memory_req
memory_req["BlackEdder/ggplotd"]=high
memory_req["BBasile/iz"]=high
memory_req["dlang-community/D-Scanner"]=high
memory_req["vibe-d/vibe-core+select"]=high
memory_req["vibe-d/vibe-core+epoll"]=high
memory_req["vibe-d/vibe.d+vibe-core-base"]=high
memory_req["vibe-d/vibe.d+libevent-base"]=high
memory_req["vibe-d/vibe.d+libasync-base"]=high
memory_req["libmir/mir-algorithm"]=high
memory_req["sociomantic-tsunami/ocean"]=high
memory_req["dlang-bots/dlang-bot"]=high
memory_req["dlang/dub"]=high
# Force long-running tasks to be on the low-end machines
memory_req["vibe-d/vibe.d+libevent-examples"]=low
memory_req["vibe-d/vibe.d+vibe-core-examples"]=low
memory_req["vibe-d/vibe.d+libevent-tests"]=low
memory_req["vibe-d/vibe.d+vibe-core-tests"]=low


for project_name in "${projects[@]}" ; do
    project="$(echo "$project_name" | sed "s/\([^+]*\)+.*/\1/")"
cat << EOF
  - command: |
      # just to be sure there isn't anything old left
      git clean -ffdxq .

      # download the distribution archive
      buildkite-agent artifact download distribution.tar.xz .
      tar xfJ distribution.tar.xz

      export REPO_URL="https://github.com/${project}"
      export REPO_DIR="$(echo "${project_name}" | tr '/' '-')"
      export REPO_FULL_NAME="${project_name}"
      rm -rf buildkite
      mv distribution/buildkite buildkite
      ./buildkite/build_project.sh
    label: "${project_name}"
    env:
      DC: dmd
      DMD: dmd
EOF

if [ "${memory_req["$project_name"]:-x}" != "x" ] ; then
cat << EOF
    agents:
      - "memory=${memory_req["$project_name"]}"
EOF
fi

done