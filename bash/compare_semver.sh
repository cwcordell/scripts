# write a bash script that compares two semver strings and dispays an error if not equal
pckgVer="10.4.2"
brchVer="10.4.2"

echo "Comparing the Semantic Version and the Release Branch Version ..."
if [[ "$pckgVer" ==  "$brchVer" ]]; then
    echo "  OK - The Semantic Version ($pckgVer) and Release Branch Version ($brchVer) match"
    exit 0
fi

echo "  Error: mismatched Semantic Version ($pckgVer) and Release Branch Version ($brchVer)" >&2
echo "    Ensure that the package.json version and the version in the branch name are the same."
exit 1