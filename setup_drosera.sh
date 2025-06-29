#!/bin/bash

# Function to check if a command was successful
check_command() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed"
        exit 1
    fi
}

# Print section header
print_header() {
    echo "----------------------------------------"
    echo "$1"
    echo "----------------------------------------"
}

# Main setup process
main() {
    print_header "Starting Drosera Setup Process"

    # Install Drosera CLI
    print_header "Installing Drosera CLI"
    curl -L https://app.drosera.io/install | bash
    check_command "Drosera CLI installation"
    source /root/.bashrc
    droseraup
    check_command "Drosera initialization"

    # Install Foundry CLI
    print_header "Installing Foundry CLI"
    curl -L https://foundry.paradigm.xyz | bash
    check_command "Foundry CLI installation"
    source /root/.bashrc
    foundryup
    check_command "Foundry initialization"

    # Install Bun
    print_header "Installing Bun"
    curl -fsSL https://bun.sh/install | bash
    check_command "Bun installation"
    source /root/.bashrc

    # Create and setup trap directory
    print_header "Setting up Trap Directory"
    mkdir -p my-drosera-trap
    cd my-drosera-trap
    check_command "Directory creation"

    # Configure Git with default values
    print_header "GitHub Configuration"
    git config --global user.email "drosera@example.com"
    git config --global user.name "drosera-user"
    check_command "Git configuration"

    # Initialize Trap
    print_header "Initializing Trap"
    forge init -t drosera-network/trap-foundry-template
    check_command "Trap initialization"

    # Install dependencies and build
    print_header "Installing Dependencies and Building"
    bun install
    check_command "Bun dependencies installation"
    forge build
    check_command "Forge build"

    print_header "Setup Complete!"
    echo "Your Drosera trap environment has been successfully set up!"
}

# Run the main function
main 