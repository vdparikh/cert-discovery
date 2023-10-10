#!/bin/bash

# Initialize an array to store certificate information
certificates=()

# Error handling function
handle_error() {
    local message="$1"
    echo "Error: $message" >&2
    exit 1
}

# Search for PEM files on the system
find_pem_files() {
    local search_dirs=("/path/to/possible/certificate/directories" "/another/possible/directory")
    
    for dir in "${search_dirs[@]}"; do
        if [ -d "$dir" ]; then
            find "$dir" -type f \( -iname "*.pem" -o -iname "*.crt" \) -print | while read -r pem_file; do
                process_pem_file "$pem_file"
            done
        fi
    done
}

# Process a PEM file
process_pem_file() {
    local pem_file="$1"
    if [ -f "$pem_file" ]; then
        echo "Processing PEM file: $pem_file"
        
        # Use OpenSSL to get certificate information
        cert_info=$(openssl x509 -noout -text -in "$pem_file" 2>/dev/null)
        if [ $? -eq 0 ]; then
            certificates+=("$cert_info")
        else
            handle_error "Failed to process $pem_file"
        fi
    else
        handle_error "PEM file not found: $pem_file"
    fi
}

# Search for Java keystore files on the system
find_keystore_files() {
    local search_dirs=("/path/to/possible/keystore/directories" "/another/possible/directory")
    
    for dir in "${search_dirs[@]}"; do
        if [ -d "$dir" ]; then
            find "$dir" -type f \( -iname "*.jks" -o -iname "*.p12" \) -print | while read -r keystore_file; do
                process_keystore "$keystore_file"
            done
        fi
    done
}

# Process a Java keystore file
process_keystore() {
    local keystore_file="$1"
    if [ -f "$keystore_file" ]; then
        echo "Processing keystore file: $keystore_file"
        
        # Use keytool to list certificates in the keystore
        while IFS= read -r entry; do
            if [ "$entry" != "" ]; then
                cert_info=$(keytool -list -v -keystore "$keystore_file" -storepass changeit -alias "$entry" 2>/dev/null)
                if [ $? -eq 0 ]; then
                    certificates+=("$cert_info")
                else
                    handle_error "Failed to list certificates in $keystore_file"
                fi
            fi
        done < <(keytool -list -keystore "$keystore_file" -storepass changeit -v 2>/dev/null | grep 'Alias name:')
    else
        handle_error "Keystore file not found: $keystore_file"
    fi
}

# Search for PEM files and Java keystore files
find_pem_files
find_keystore_files

# Output the certificate information in JSON format
if [ ${#certificates[@]} -eq 0 ]; then
    handle_error "No certificates found"
else
    echo "[" > certificate_inventory.json
    for ((i=0; i<${#certificates[@]}; i++)); do
        echo "${certificates[$i]}"
        if [[ $i -lt $((${#certificates[@]}-1)) ]]; then
            echo ","
        fi
    done >> certificate_inventory.json
    echo "]" >> certificate_inventory.json

    echo "Certificate inventory has been saved to certificate_inventory.json"
fi
