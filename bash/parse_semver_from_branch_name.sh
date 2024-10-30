# Validate then parse the semantic version from a provide release branch name

# Check if the branch name is in the correct format
function psfbn_validate_branch_name() {
  if [[ $1 =~ ^(R|r)elease/(R|r)?(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(\.(0|[1-9][0-9]*))*$ ]]; then
    echo "$1"
  else
    echo ""
  fi
}

# Extract the version number from the branch name
function psfbn_parse_release_version() {
  local semver=$(echo "$1" | xargs | tr '[:upper:]' '[:lower:]' | sed -n 's/^release\/r\([0-9]*\.[0-9]*\(\.[0-9]*\)*\)$/\1/p')
  if [[ "$semver" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(\.(0|[1-9][0-9]*))*$ ]]; then
    echo "$semver"
  else
    echo "error"
  fi
  return 0
}

# Print usage
function psfbn_print_usage() {
  echo
  echo "Usage: parse_semver_from_branch_name.sh [OPTIONS] BRANCH_NAME"
  echo
  echo "A script to validate and parse the semantic version from a branch, intended for a release,"
  echo "where the name is in the form 'Release/R#.#.#', e.g. 'Release/R5.2.1'".
  echo
  echo "Options:"
  echo "  -v        Verbose output, prints errors and echos the raw version on success"
  echo "  -o        Set parsed semvar as output in Azure Pipelines"
  echo "  -t        Run tests"
  echo "  -h        Print usage"
  echo
  echo "Branch Name:"
  echo "The branch name to validate and parse, e.g. 'Release/R5.2.1'."
  echo "The branch name must begin with 'Release/' or 'release/', may have an optional semver prefix of 'R' or 'r',"
  echo "and must end with a semver containing a major and minor value with an optional patch value."
  echo
  echo
}

# ************************************************************
# Testing
# ************************************************************
# Run test cases to validate the psfbn_validate_branch_name and psfbn_parse_release_version using both valid and invalid branch names
# Test cases are comprised of valid branch name prefixes, invalid branch name prefixes, accepted semantic versions, and semantic versions not accepted

psfbn_test() {
  local valid_prefixes=("Release/R" "release/R" "Release/r" "release/r")
  local invalid_prefixes=("R" "r" "R/" "r/" "R/r" "r/R" "RELEASE/" "RELEASE" "REleasE/" "REleasE" "RELEASE/R" "REleasE/R" "Release/ R"  "Release/R "Release/v"  "Release/V" " "/" " " "." "v")
  local valid_semvers=("5.2.1" "5.2" "0.0.0" "0.0" "0.0.1" "1.1.0" "255.256.257" "5.2.1.1")
  local invalid_semvers=("5" "5." "5.2." "0")

  # Compose invalid branch names into an array named invalid_branch_names
  local invalid_branch_names=()
  for prefix in "${invalid_prefixes[@]}"; do
    for semver in "${invalid_semvers[@]}"; do
      invalid_branch_names+=("$prefix$semver")
    done
    for semver in "${valid_semvers[@]}"; do
      invalid_branch_names+=("$prefix$semver")
    done
  done
  for prefix in "${valid_prefixes[@]}"; do
    for semver in "${invalid_semvers[@]}"; do
      invalid_branch_names+=("$prefix$semver")
    done
  done

  # Run test cases for the psfbn_validate_branch_name function
  # Valid branch names
  local valid_errors=0
  local valid_test_count=0
  printf "\nRunning valid branch name test cases ... "
  for prefix in "${valid_prefixes[@]}"; do
    for semver in "${valid_semvers[@]}"; do
      valid_test_count=$((valid_test_count + 2))
      local branch_name="$prefix$semver"

      # Validate the branch name
      local psfbn_validate_branch_name_result=$(psfbn_validate_branch_name $branch_name)
      if [ -z "$psfbn_validate_branch_name_result" ]; then
        [ $valid_errors -eq 0 ] && echo
        valid_errors=$((valid_errors + 1))
        echo "\t- Test failed: psfbn_validate_branch_name($branch_name) returned as invalid but expected valid"
      fi

      # Parse the release version
      local psfbn_parse_release_version_result=$(psfbn_parse_release_version $branch_name)
      if [ "$psfbn_parse_release_version_result" != "$semver" ]; then
        [ $valid_errors -eq 0 ] && echo
        valid_errors=$((valid_errors + 1))
        echo "\t- Test failed: psfbn_parse_release_version($branch_name) returned $psfbn_parse_release_version_result but expected $semver"
      fi
    done
  done

  if [ $valid_errors -eq 0 ]; then
    echo "OK"
  fi

  # Invalid branch names
  local invalid_errors=0
  printf "Running invalid branch name test cases ... "
  for branch_name in "${invalid_branch_names[@]}"; do
    local result=$(psfbn_validate_branch_name $branch_name)
    if [ ! -z "$result" ]; then
    [ $invalid_errors -eq 0 ] && echo
      invalid_errors=$((invalid_errors + 1))
      echo "\t\t- Test failed: psfbn_validate_branch_name($branch_name) returned as valid but expected invalid"
    fi
  done

  if [ $invalid_errors -eq 0 ]; then
    echo "OK"
  fi

  echo
  echo "Tests results: $((valid_errors + invalid_errors)) failed of $((valid_test_count + ${#invalid_branch_names[@]})) tests"
  echo

  if [ $((valid_errors + invalid_errors)) -gt 0 ]; then
    exit 1
  else
    exit 0
  fi
}

# ************************************************************
# Main
# ************************************************************
function psfbn_main() {
  local VERBOSE=false
  local AZP_OUTPUT=false
  local TEST=false

  while getopts "voth" opt; do
    case $opt in
      v)
        VERBOSE=true
        ;;
      o)
        AZP_OUTPUT=true
        ;;
      t)
        TEST=true
        ;;
      h)
        psfbn_print_usage
        return 0
        ;;
      \?)
        echo "Invalid option: -$OPTARG" >&2; echo; psfbn_print_usage;
        return 1
        ;;
    esac
  done

  shift $((OPTIND-1))

  if [ $TEST = true ]; then
    psfbn_test
    return 0
  fi

  if [ -z "$1" ]; then
    echo "Error: Missing branch name"
    return 1
  fi

  local BRANCH=$1

  # Check if the branch name is in the correct format
  if [ $VERBOSE = true ]; then
    echo "\tChecking if the branch name '$BRANCH' is in a valid format ..."
  fi

  local check_branch_name=$(psfbn_validate_branch_name $BRANCH)

  if [ -z "$check_branch_name" ]; then
    echo "\t\tError: The branch $BRANCH is not in a valid format" >&2;
    echo "\t\t\tThe branch name must be in the form '(R|r)elease/(R|r)#.#.#', e.g. 'Release/R5.2.1'"
    # exit 1
  fi

  if [ $VERBOSE = true ]; then
    echo "\t\t$BRANCH is a valid release branch"
  fi

  # Extract the version number from the branch name
  if [ $VERBOSE = true ]; then
    echo "\tParsing version from release branch name $BRANCH ..."
  fi

  local RELEASE_VERSION=$(psfbn_parse_release_version $BRANCH)

  if [ $VERBOSE = true ]; then
    echo "\t\tRelease version: $RELEASE_VERSION"
  else
    echo $RELEASE_VERSION
  fi

  # Set the parsed version as output in Azure Pipelines
  if [ $AZP_OUTPUT = true ]; then
    echo "##vso[task.setvariable variable=releaseVersion;isoutput=true]$RELEASE_VERSION"
  fi
}

# ************************************************************
# Execute the script
# ************************************************************
# Run the main function
psfbn_main "$@"

# End of script
