#!/bin/bash

# set -x

# Function to display usage
display_usage() {
  echo "Usage: $0 -n <app_config_name> -e <endpoint> [-k <key>] [-v <value>] [-l <label>] [-d] [-p]"
  echo "Example: $0 -n myAppConfig -e https://myappconfig.azconfig.io -k myKey -v myValue -l myLabel -d -p"
  echo "Defaults: key=AIS_ReleaseVersion, label=AIS_ReleaseVersion"
  echo "Options:"
  echo "  -d    Dry run. Display the actions without making any changes. If the precheck option is enabled, a GET call will be made to retrieve the current value from the App Config Store and check it before continuing."
  echo "          The Dry Run and Precheck options can be used as a smoke test when used together."
  echo "  -p    Precheck. Get the current value of the key from the App Config store and compare with the new value before updating."
  echo "  -h    Display usage information."
}

# Default values
DEFAULT_KEY="AIS_ReleaseVersion"
DEFAULT_LABEL="AIS_ReleaseVersion"
DRY_RUN=false
PRECHECK=false
APP_CONFIG_NAME="defaultAppConfig"

# Parse options
while getopts "n:e:k:v:l:dph" opt; do
  case $opt in
    n) echo "Setting App Config name $OPTARG"
        APP_CONFIG_NAME="$OPTARG" ;;
    e) echo "Setting Endpoint $OPTARG"
        ENDPOINT="$OPTARG ";;
    k) KEY="$OPTARG" ;;
    v) VALUE="$OPTARG" ;;
    l) LABEL="$OPTARG" ;;
    d) DRY_RUN=true ;;
    p) PRECHECK=true ;;
    h) display_usage
       exit 0 ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      display_usage
      exit 1 ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      display_usage
      exit 1 ;;
  esac
done

shift "$((OPTIND-1))"

# Set default values if not provided
KEY=${KEY:-$DEFAULT_KEY}
LABEL=${LABEL:-$DEFAULT_LABEL}
ERRORS=0

echo "App Configuration Name: $APP_CONFIG_NAME"
echo "Endpoint: $ENDPOINT"
echo "Value: $VALUE"

# Check that required variables are set
if [[ -z "$APP_CONFIG_NAME" ]]; then
  echo "Error: Missing App Configuration name."
  ERRORS=$((ERRORS + 1))
fi
if [[ -z "$ENDPOINT" ]]; then
  echo "Error: Missing endpoint."
  ERRORS=$((ERRORS + 1))
fi
if [[ -z "$VALUE" ]]; then
  echo "Error: Missing value."
  ERRORS=$((ERRORS + 1))
fi
if [[ $ERRORS -gt 0 ]]; then
  echo
  display_usage
  exit 1
fi

# Get the current value in the App Configuration store
echo "Getting existing $KEY value ..."
retrieved_current_value=$(az appconfig kv show --auth-mode login -n "$APP_CONFIG_NAME" --endpoint "$ENDPOINT" --key "$KEY" --label "$LABEL" --query "value" -o tsv)
echo "$KEY is currently $VALUE."
echo

# Check if the current value needs updating
if [[ "$retrieved_current_valu" == "$VALUE" ]]; then
  echo "The $KEY already has the correct value of $VALUE."
  echo
  exit 0
fi

# Perform a dry run
if [ "$DRY_RUN" = true ]; then
  echo "Dry run: az appconfig kv set -y --auth-mode login -n \"$APP_CONFIG_NAME\" --endpoint \"$ENDPOINT\" --key \"$KEY\" --label \"$LABEL\" --value \"$VALUE\""
  echo
  exit 0
fi

# Update the value in the App Configuration store
echo "Updating key $KEY with value $VALUE ..."
echo
az appconfig kv set -y --auth-mode login -n "$APP_CONFIG_NAME" --endpoint "$ENDPOINT" --key "$KEY" --label "$LABEL" --value "$VALUE"

if [[ $? -eq 0 ]]; then
  echo "Update successful."
else
  echo "Update failed."
  exit 1
fi

# Verify the key has the correct value
echo "Verifying the key $KEY has the correct value ..."
retrieved_value=$(az appconfig kv show --auth-mode login -n "$APP_CONFIG_NAME" --endpoint "$ENDPOINT" --key "$KEY" --label "$LABEL" --query "value" -o tsv)

if [[ "$retrieved_value" == "$VALUE" ]]; then
  echo "Verification successful. The key $KEY has the correct value."
else
  echo "Verification failed. The key $KEY does not have the correct value."
  exit 1
fi
