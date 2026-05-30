#!/bin/bash

print_usage () {
    echo "03 APP STACK"
    echo " "
    echo "Usage: ./run.sh [SUBSCRIPTION] [ENVIRONMENT] [APPSTACK] [--plan] [--destroy] [--upgrade] [--force-unlock] [--import] [--state] [COMMAND ARGS...]"
    echo " "
    echo "Options:"
    echo "   --plan           Run Terraform in PLAN mode (show changes)"
    echo "   --destroy        Run Terraform in DESTROY mode"
    echo "   --upgrade        Run Terraform init with the --upgrade option"
    echo "   --force-unlock   Run Terraform force-unlock with the provided arguments"
    echo "   --import         Run Terraform import with the provided arguments"
    echo "   --state          Run Terraform state with the provided arguments"
    echo " "
    echo "Arguments:"
    echo "   SUBSCRIPTION     Name of the requested subscription in folder ../environments/"
    echo "   ENVIRONMENT      Name of the requested environment in folder ../environments/(SUBSCRIPTION)/ to"
    echo "                    execute terraform on (ENV BASE STACK)"
    echo "   APPSTACK         Name of the app stack in the environment folder to execute Terraform on"
    echo "   COMMAND ARGS...  Additional arguments to be added to the command (use to provide arguments to force-unlock, import, state, ...)"
    echo " "
}

# ---

CWD=$(dirname $(readlink -f $0))

# Initialize variables
PLAN=0
DESTROY=0
UPGRADE=0
FORCE_UNLOCK=0
IMPORT=0
STATE=0
SUBSCRIPTION=""
ENVIRONMENT=""
APPSTACK=""
COMMAND_ARGS=()

# Parse options and arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --plan)
            PLAN=1
            shift # past argument
            ;;
        --destroy)
            DESTROY=1
            shift # past argument
            ;;
        --upgrade)
            UPGRADE=1
            shift # past argument
            ;;
        --force-unlock)
            FORCE_UNLOCK=1
            shift # past argument
            ;;
        --import)
            IMPORT=1
            shift # past argument
            ;;
        --state)
            STATE=1
            shift # past argument
            ;;
        *)
            if [ -z "$SUBSCRIPTION" ]; then
                SUBSCRIPTION=$1
            elif [ -z "$ENVIRONMENT" ]; then
                ENVIRONMENT=$1
            elif [ -z "$APPSTACK" ]; then
                APPSTACK=$1
            else
                COMMAND_ARGS+=("$1")
            fi
            shift # past argument
            ;;
    esac
done

# Validate arguments
if [ -z "${SUBSCRIPTION}" ]; then
    echo "Error: missing subscription name"
    echo " "
    print_usage
    exit 1
elif [ -z "${ENVIRONMENT}" ]; then
    echo "Error: missing environment name"
    echo " "
    print_usage
    exit 1
elif [ -z "${APPSTACK}" ] && [ $FORCE_UNLOCK -eq 0 ] && [ $IMPORT -eq 0 ] && [ $STATE -eq 0 ]; then
    echo "Error: missing app stack name"
    echo " "
    print_usage
    exit 1
fi

# Check if only one command is specified
COMMAND_COUNT=$(( PLAN + DESTROY + FORCE_UNLOCK + IMPORT + STATE ))
if [ $COMMAND_COUNT -gt 1 ]; then
    echo "Error: only one of --plan, --destroy, --force-unlock, --import, or --state can be specified"
    echo " "
    print_usage
    exit 1
fi

# ---

ENV_BASE=$(realpath "$(pwd)/../environments")
TFBACKEND_PATH="${ENV_BASE}/${SUBSCRIPTION}/${ENVIRONMENT}/03_app_stack__${APPSTACK}.tfbackend"

TFVARS_PATHS=()
TFVARS_PATHS+=("${ENV_BASE}/${SUBSCRIPTION}/common.tfvars")
TFVARS_PATHS+=("${ENV_BASE}/${SUBSCRIPTION}/${ENVIRONMENT}/00_global.tfvars")
TFVARS_PATHS+=("${ENV_BASE}/${SUBSCRIPTION}/${ENVIRONMENT}/01_env_base_stack.tfvars")
TFVARS_PATHS+=("${ENV_BASE}/${SUBSCRIPTION}/${ENVIRONMENT}/02_global_stack.tfvars")
TFVARS_PATHS+=("${ENV_BASE}/${SUBSCRIPTION}/${ENVIRONMENT}/03_app_stack__${APPSTACK}.tfvars")

echo "--> Using tfbackend: ${TFBACKEND_PATH}"
echo "--> Using tfvars:"
for TFVARS_PATH in "${TFVARS_PATHS[@]}"; do
    echo "      - ${TFVARS_PATH}"
done

if [ ! -f "${TFBACKEND_PATH}" ]; then
    echo "Error: missing tfbackend file: ${TFBACKEND_PATH}"
    echo " "
    print_usage
    exit 1
fi

for TFVARS_PATH in "${TFVARS_PATHS[@]}"; do
    if [ ! -f "${TFVARS_PATH}" ]; then
        echo "Error: missing tfvars file: ${TFVARS_PATH}"
        echo " "
        print_usage
        exit 1
    fi
done

TFVARS_FILE_ARGS=()
for TFVARS_PATH in "${TFVARS_PATHS[@]}"; do
    TFVARS_FILE_ARGS+=("--var-file" "${TFVARS_PATH}")
done

if [ -d "$(pwd)/.terraform" ] && [ -e "$(pwd)/.terraform/terraform.tfstate" ]; then
    echo "---> Removing old .terraform/terraform.tfstate file ..."
    rm -rf "$(pwd)/.terraform/terraform.tfstate"
fi

# Terraform init command
INIT_CMD="terraform init --backend-config ${TFBACKEND_PATH}"
if [ $UPGRADE -eq 1 ]; then
    INIT_CMD="$INIT_CMD --upgrade"
fi
echo "--> Running terraform INIT:"
$INIT_CMD

if [ $FORCE_UNLOCK -eq 1 ]; then
    echo "--> Running terraform FORCE-UNLOCK:"
    terraform force-unlock "${COMMAND_ARGS[@]}"
elif [ $STATE -eq 1 ]; then
    echo "--> Running terraform STATE:"
    terraform state "${COMMAND_ARGS[@]}"
elif [ $IMPORT -eq 1 ]; then
    echo "--> Running terraform IMPORT:"
    terraform import "${TFVARS_FILE_ARGS[@]}" "${COMMAND_ARGS[@]}"
elif [ $PLAN -eq 1 ]; then
    echo "--> Running terraform PLAN:"
    terraform plan "${TFVARS_FILE_ARGS[@]}" "${COMMAND_ARGS[@]}"
elif [ $DESTROY -eq 1 ]; then
    echo "--> Running terraform DESTROY:"
    terraform destroy "${TFVARS_FILE_ARGS[@]}" "${COMMAND_ARGS[@]}"
else
    echo "--> Running terraform APPLY:"
    terraform apply "${TFVARS_FILE_ARGS[@]}" "${COMMAND_ARGS[@]}"
fi

echo "Done"
